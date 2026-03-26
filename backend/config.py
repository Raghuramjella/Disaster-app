import os
from dotenv import load_dotenv

load_dotenv()

# JWT
SECRET_KEY: str = os.getenv("SECRET_KEY", "change-this-secret-key")
ALGORITHM: str = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

# Firebase
FIREBASE_CREDENTIALS_PATH: str = os.getenv(
    "FIREBASE_CREDENTIALS_PATH", "firebase_service_account.json"
)
FIREBASE_STORAGE_BUCKET: str = os.getenv("FIREBASE_STORAGE_BUCKET", "")

# Gmail (for OTP emails)
GMAIL_USER: str = os.getenv("GMAIL_USER", "")
GMAIL_APP_PASSWORD: str = os.getenv("GMAIL_APP_PASSWORD", "")

# Google Earth Engine (optional)
GEE_SERVICE_ACCOUNT: str = os.getenv("GEE_SERVICE_ACCOUNT", "")
GEE_KEY_FILE: str = os.getenv("GEE_KEY_FILE", "")
