import random
from datetime import datetime, timedelta

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel

from database import db, get_next_id
from models.user import UserCreate, UserLogin, UserResponse
from services.auth_service import create_access_token, hash_password, verify_password
from services.email_service import send_reset_email

router = APIRouter(prefix="/auth", tags=["auth"])


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    email: str
    reset_code: str
    new_password: str


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user: UserCreate):
    # Check duplicate email
    existing = db.collection("users").where("email", "==", user.email).limit(1).get()
    if len(existing) > 0:
        raise HTTPException(status_code=400, detail="Email already registered")

    user_id = get_next_id("users")
    user_data = {
        "id": user_id,
        "name": user.name.strip(),
        "email": user.email.lower(),
        "password_hash": hash_password(user.password),
        "created_at": datetime.utcnow().isoformat(),
    }
    db.collection("users").document(str(user_id)).set(user_data)

    token = create_access_token({"sub": str(user_id), "email": user.email})
    return UserResponse(id=user_id, name=user.name, email=user.email, access_token=token)


@router.post("/login", response_model=UserResponse)
def login(creds: UserLogin):
    users = db.collection("users").where("email", "==", creds.email.lower()).limit(1).get()
    if not users:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    user_doc = users[0].to_dict()
    if not verify_password(creds.password, user_doc["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = create_access_token(
        {"sub": str(user_doc["id"]), "email": user_doc["email"]}
    )
    return UserResponse(
        id=user_doc["id"],
        name=user_doc["name"],
        email=user_doc["email"],
        access_token=token,
    )


@router.post("/forgot-password")
def forgot_password(req: ForgotPasswordRequest):
    users = db.collection("users").where("email", "==", req.email.lower()).limit(1).get()
    if not users:
        raise HTTPException(status_code=404, detail="No account found with this email")

    user_data = users[0].to_dict()
    code = str(random.randint(100000, 999999))
    expiry = (datetime.utcnow() + timedelta(minutes=15)).isoformat()

    db.collection("reset_codes").document(req.email.lower()).set({
        "code": code,
        "expires_at": expiry,
    })

    try:
        send_reset_email(req.email.lower(), code, user_data.get("name", "User"))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")

    return {"message": "Reset code sent to your email"}


@router.post("/reset-password")
def reset_password(req: ResetPasswordRequest):
    doc_ref = db.collection("reset_codes").document(req.email.lower())
    doc = doc_ref.get()
    if not doc.exists:
        raise HTTPException(status_code=400, detail="No reset code found. Request a new one.")

    data = doc.to_dict()
    if data["code"] != req.reset_code:
        raise HTTPException(status_code=400, detail="Invalid reset code")

    if datetime.utcnow() > datetime.fromisoformat(data["expires_at"]):
        doc_ref.delete()
        raise HTTPException(status_code=400, detail="Reset code has expired. Request a new one.")

    users = db.collection("users").where("email", "==", req.email.lower()).limit(1).get()
    if not users:
        raise HTTPException(status_code=404, detail="User not found")

    users[0].reference.update({"password_hash": hash_password(req.new_password)})
    doc_ref.delete()

    return {"message": "Password reset successfully"}
