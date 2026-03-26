"""
FastAPI dependency — resolves the current authenticated user from a JWT.
"""
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError

from database import db
from services.auth_service import decode_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    """
    Decodes the Bearer JWT and returns the user document from Firestore.
    Raises HTTP 401 on any failure.
    """
    credentials_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_token(token)
        user_id: str = payload.get("sub")
        if not user_id:
            raise credentials_exc
    except JWTError:
        raise credentials_exc

    user_doc = db.collection("users").document(user_id).get()
    if not user_doc.exists:
        raise credentials_exc

    return user_doc.to_dict()
