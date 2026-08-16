from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

import jwt
from fastapi import Header, HTTPException, status
from jwt import InvalidTokenError

from app.config import settings


@dataclass(frozen=True)
class FirebaseIdentity:
    uid: str
    phone_e164: str | None = None
    email: str | None = None


def create_access_token(uid: str, email: str) -> str:
    now = datetime.now(UTC)
    return jwt.encode(
        {
            "sub": uid,
            "email": email,
            "iss": "rally",
            "iat": now,
            "exp": now + timedelta(days=settings.auth_token_days),
        },
        settings.auth_secret,
        algorithm="HS256",
    )


def new_account_uid() -> str:
    return f"web-{uuid.uuid4()}"


def _verify_rally_token(token: str) -> FirebaseIdentity | None:
    try:
        decoded = jwt.decode(
            token,
            settings.auth_secret,
            algorithms=["HS256"],
            issuer="rally",
        )
    except InvalidTokenError:
        return None
    uid = decoded.get("sub")
    email = decoded.get("email")
    if not uid or not email:
        return None
    return FirebaseIdentity(uid=uid, email=email)


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

    rally_identity = _verify_rally_token(token)
    if rally_identity:
        return rally_identity

    _init_admin_once()
    if not settings.firebase_credentials_path:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "firebase not configured")

    from firebase_admin import auth as fb_auth

    try:
        decoded = fb_auth.verify_id_token(token)
    except Exception as e:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, f"invalid token: {e}") from e

    phone = decoded.get("phone_number")
    email = decoded.get("email")
    if not phone and not email:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "token has no identity")
    return FirebaseIdentity(uid=decoded["uid"], phone_e164=phone, email=email)
