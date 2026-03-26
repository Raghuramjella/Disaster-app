from fastapi import APIRouter, Depends, HTTPException, Response

from database import db
from models.report import ReportResponse
from routes.deps import get_current_user
from services.report_service import generate_pdf_report

router = APIRouter(prefix="/reports", tags=["reports"])


def _get_report_doc(claim_id: int):
    docs = db.collection("reports").where("claim_id", "==", claim_id).limit(1).get()
    if not docs:
        raise HTTPException(status_code=404, detail="Report not found")
    return docs[0].to_dict()


@router.get("/{claim_id}", response_model=ReportResponse)
def get_report(claim_id: int, current_user: dict = Depends(get_current_user)):
    """Return the compensation report for a claim."""
    data = _get_report_doc(claim_id)
    return ReportResponse(**data)


@router.get("/{claim_id}/pdf")
def download_pdf(claim_id: int, current_user: dict = Depends(get_current_user)):
    """Generate and stream a PDF compensation report."""
    report_data = _get_report_doc(claim_id)

    claim_doc = db.collection("claims").document(str(claim_id)).get()
    if not claim_doc.exists:
        raise HTTPException(status_code=404, detail="Claim not found")
    claim_data = claim_doc.to_dict()

    if claim_data["user_id"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="Access denied")

    pdf_bytes = generate_pdf_report(claim_data, report_data, current_user["name"])

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="report_{claim_id}.pdf"'
        },
    )
