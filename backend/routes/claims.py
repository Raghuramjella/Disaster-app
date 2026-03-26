import uuid
from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile

from database import bucket, db, get_next_id
from models.claim import ClaimResponse
from models.report import ReportResponse
from routes.deps import get_current_user
from services.gee_service import get_after_image, get_before_image
from services.image_service import _disaster_scene_score, compute_similarity, verify_photo_authenticity
from services.scoring_service import compute_damage

router = APIRouter(prefix="/claims", tags=["claims"])


# ── Helpers ───────────────────────────────────────────────────────────────────

def _claim_response(d: dict) -> dict:
    return {
        "id": d["id"],
        "disaster_type": d["disaster_type"],
        "location": d["location"],
        "description": d["description"],
        "status": d["status"],
        "submitted_at": d["submitted_at"],
        "after_image_url": d.get("after_image_url"),
    }


def _report_response(d: dict) -> dict:
    return {
        "id": d["id"],
        "claim_id": d["claim_id"],
        "similarity_score": d["similarity_score"],
        "damage_tier": d["damage_tier"],
        "loss_percentage": d["loss_percentage"],
        "compensation_amount": d["compensation_amount"],
        "pdf_url": d.get("pdf_url"),
        "generated_at": d["generated_at"],
        "satellite_before_url": d.get("satellite_before_url"),
        "satellite_after_url": d.get("satellite_after_url"),
        "authenticity_score": d.get("authenticity_score"),
        "photo_verified": d.get("photo_verified"),
    }


def _upload_bytes(data: bytes, path: str, content_type: str = "image/jpeg") -> str:
    """Upload bytes to Firebase Storage and return a public URL."""
    blob = bucket.blob(path)
    blob.upload_from_string(data, content_type=content_type)
    blob.make_public()
    return blob.public_url


# ── Routes ────────────────────────────────────────────────────────────────────

@router.get("", response_model=List[ClaimResponse])
def get_claims(current_user: dict = Depends(get_current_user)):
    """Return all claims belonging to the authenticated user."""
    docs = (
        db.collection("claims")
        .where("user_id", "==", current_user["id"])
        .get()
    )
    claims = [_claim_response(doc.to_dict()) for doc in docs]
    claims.sort(key=lambda c: c["submitted_at"], reverse=True)
    return claims


@router.get("/{claim_id}", response_model=ClaimResponse)
def get_claim(claim_id: int, current_user: dict = Depends(get_current_user)):
    """Return a single claim by ID."""
    doc = db.collection("claims").document(str(claim_id)).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Claim not found")

    data = doc.to_dict()
    if data["user_id"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="Access denied")

    return _claim_response(data)


@router.post("", status_code=201)
def submit_claim(
    disaster_type: str = Form(...),
    location: str = Form(...),
    description: str = Form(...),
    property_type: str = Form(...),
    property_value: float = Form(...),
    incident_date: str = Form(...),
    after_image: UploadFile = File(...),
    latitude: float = Form(None),
    longitude: float = Form(None),
    current_user: dict = Depends(get_current_user),
):
    """
    Submit a new disaster claim.

    Pipeline
    --------
    1. Upload the user's after-disaster photo to Firebase Storage.
    2. Fetch the pre-disaster satellite image from GEE (30 days before incident).
    3. Fetch the post-disaster satellite image from GEE (30 days after incident).
    4. Upload both satellite images to Firebase Storage.
    5. Damage assessment  : compare before vs after satellite images.
       Fallback            : single-image analysis of the user's photo.
    6. Authenticity check : compare user's photo vs satellite after-image.
       Verifies the uploaded photo is consistent with the disaster location.
    7. Persist claim + report to Firestore and return both.
    """
    # ── 1. Upload user's after-disaster photo ────────────────────────────────
    after_bytes = after_image.file.read()
    user_photo_url = _upload_bytes(
        after_bytes,
        f"claims/{uuid.uuid4()}/{after_image.filename or 'after.jpg'}",
        after_image.content_type or "image/jpeg",
    )

    # ── 2 & 3. Fetch satellite images from GEE ───────────────────────────────
    lat = latitude if latitude is not None else 17.0
    lon = longitude if longitude is not None else 82.0
    incident_day = incident_date[:10]

    print(f"[GEE] Fetching satellite images for ({lat}, {lon}) around {incident_day}")

    # GEE Sentinel-2 archive has ~7-day processing lag.
    # If the incident is less than 10 days ago there is no post-disaster image
    # in the archive yet — skip the after-fetch to avoid GEE returning the same
    # tile as the before-image, which would produce a false "no damage" score.
    incident_dt = datetime.strptime(incident_day, "%Y-%m-%d")
    days_since = (datetime.utcnow() - incident_dt).days

    # Always fetch both satellite images — before AND after — for display and comparison.
    before_bytes = get_before_image(latitude=lat, longitude=lon, date_before=incident_day)
    after_sat_bytes = get_after_image(latitude=lat, longitude=lon, date_after=incident_day)

    if days_since < 10:
        print(f"[GEE] Incident only {days_since} day(s) ago — after image may be from same pass as before")

    # ── 4. Upload satellite images to Firebase Storage ───────────────────────
    claim_id = get_next_id("claims")

    sat_before_url = None
    sat_after_url = None

    if before_bytes:
        sat_before_url = _upload_bytes(
            before_bytes, f"satellite/{claim_id}/before.jpg"
        )
        print(f"[GEE] Before image uploaded: {sat_before_url}")
    else:
        print("[GEE] No before satellite image available — using fallback")

    if after_sat_bytes:
        sat_after_url = _upload_bytes(
            after_sat_bytes, f"satellite/{claim_id}/after.jpg"
        )
        print(f"[GEE] After image uploaded: {sat_after_url}")
    else:
        print("[GEE] No after satellite image available — using fallback")

    # ── 5. Damage assessment — satellite images only ─────────────────────────
    # Compensation is derived exclusively from comparing the before vs after
    # satellite images. The user's uploaded photo plays NO part in damage scoring.
    if before_bytes and after_sat_bytes:
        similarity_score = compute_similarity(before_bytes, after_sat_bytes)
        print(f"[DAMAGE] Satellite before vs after similarity: {similarity_score}")
        damage_tier, loss_percentage, compensation_amount = compute_damage(
            similarity_score, property_value
        )
        claim_status = "verified"
    else:
        # One or both satellite images unavailable — cannot assess damage.
        similarity_score = 1.0
        damage_tier = "Pending"
        loss_percentage = 0.0
        compensation_amount = 0.0
        claim_status = "pending_review"
        print("[DAMAGE] Satellite images unavailable — claim flagged for manual review")

    # ── 6. Authenticity verification (informational only) ────────────────────
    # Photo authenticity is shown in the report for transparency but does NOT
    # affect the compensation amount — only satellite comparison determines that.
    if after_sat_bytes:
        authenticity_score, photo_verified = verify_photo_authenticity(
            after_bytes, after_sat_bytes
        )
        print(f"[AUTH] Score: {authenticity_score}, verified: {photo_verified}")
    else:
        d_score = _disaster_scene_score(after_bytes)
        authenticity_score = round(d_score, 4)
        photo_verified = d_score >= 0.55
        print(f"[AUTH] Scene-only score: {authenticity_score}, verified: {photo_verified}")

    # ── 7. Persist to Firestore ───────────────────────────────────────────────
    now = datetime.utcnow().isoformat()

    claim_data = {
        "id": claim_id,
        "user_id": current_user["id"],
        "disaster_type": disaster_type,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "description": description,
        "property_type": property_type,
        "property_value": property_value,
        "incident_date": incident_date,
        "after_image_url": user_photo_url,
        "status": claim_status,
        "submitted_at": now,
    }
    db.collection("claims").document(str(claim_id)).set(claim_data)

    report_id = get_next_id("reports")
    report_data = {
        "id": report_id,
        "claim_id": claim_id,
        "similarity_score": similarity_score,
        "damage_tier": damage_tier,
        "loss_percentage": loss_percentage,
        "compensation_amount": compensation_amount,
        "pdf_url": None,
        "generated_at": now,
        "satellite_before_url": sat_before_url,
        "satellite_after_url": sat_after_url,
        "authenticity_score": authenticity_score,
        "photo_verified": photo_verified,
    }
    db.collection("reports").document(str(report_id)).set(report_data)

    return {
        "claim": _claim_response(claim_data),
        "report": _report_response(report_data),
    }
