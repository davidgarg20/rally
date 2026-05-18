from __future__ import annotations
from dataclasses import dataclass
from fastapi import Header, HTTPException, status

from app.config import settings

@dataclass(frozen=True)
class FirebaseIdentity:
    uid: str
    phone_e164: str


_initialized = False

def _init_admin_once() -> None:
    global _initialized
    if _initialized:
        return
    if not settings.firebase_credentials_path:
        _initialized = True
        return
    import firebase_admin
    from firebase_admin import credentials
    cred = credentials.Certificate(settings.firebase_credentials_path)
    firebase_admin.initialize_app(cred)
    _initialized = True


async def verify_id_token(
    authorization: str | None = Header(default=None),
) -> FirebaseIdentity:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing bearer token")
    token = authorization.split(" ", 1)[1].strip()

    if settings.env == "dev" and token.startswith("dev:"):
        parts = token.split(":")
        if len(parts) != 3:
            raise HTTPException(status.HTTP_401_UNAUTHORIZED, "bad dev token")
        return FirebaseIdentity(uid=parts[1], phone_e164=parts[2])

    _init_admin_once()
    if not settings.firebase_credentials_path:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "firebase not configured")

    from firebase_admin import auth as fb_auth
    try:
        decoded = fb_auth.verify_id_token(token)
    except Exception as e:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, f"invalid token: {e}") from e

    phone = decoded.get("phone_number")
    if not phone:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "token has no phone_number")
    return FirebaseIdentity(uid=decoded["uid"], phone_e164=phone)
