import base64
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routes import auth, claims, images, reports

# ── Write key files from env vars (production / Railway deployment) ───────────
# In production the actual JSON files are not committed to git.
# Instead their contents are stored as base64-encoded environment variables
# FIREBASE_CREDENTIALS_B64 and GEE_KEY_B64.  Decode and write them to disk
# before anything else imports them.

def _write_key_file(env_var: str, path_env_var: str, default_path: str) -> None:
    b64 = os.getenv(env_var, "")
    if b64:
        with open(default_path, "wb") as f:
            f.write(base64.b64decode(b64))
        os.environ[path_env_var] = default_path

_write_key_file("FIREBASE_CREDENTIALS_B64", "FIREBASE_CREDENTIALS_PATH", "firebase_key.json")
_write_key_file("GEE_KEY_B64",              "GEE_KEY_FILE",               "gee_key.json")

app = FastAPI(
    title="Livelihood Loss Compensation API",
    description="Automated disaster compensation system — RGUKT CSE",
    version="1.0.0",
)

# ── CORS ─────────────────────────────────────────────────────────────────────
# Allow all origins during development; tighten for production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(claims.router)
app.include_router(reports.router)
app.include_router(images.router)


# ── Root ──────────────────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {"message": "Livelihood Loss Compensation API", "version": "1.0.0"}


@app.get("/health")
def health():
    return {"status": "ok"}
