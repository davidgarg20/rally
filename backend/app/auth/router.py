from __future__ import annotations

from fastapi import APIRouter
from pwdlib import PasswordHash
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import select

from app.auth.firebase import create_access_token, new_account_uid
from app.db.models import UserAccount
from app.deps import DbSession
from app.errors import Conflict, Forbidden

router = APIRouter(prefix="/auth", tags=["auth"])
password_hash = PasswordHash.recommended()


class Credentials(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


@router.post("/register", response_model=TokenOut, status_code=201)
async def register(body: Credentials, session: DbSession) -> TokenOut:
    email = body.email.lower().strip()
    existing = (
        await session.execute(select(UserAccount).where(UserAccount.email == email))
    ).scalar_one_or_none()
    if existing:
        raise Conflict("email already registered", code="email_registered")

    account = UserAccount(
        uid=new_account_uid(),
        email=email,
        password_hash=password_hash.hash(body.password),
    )
    session.add(account)
    await session.commit()
    return TokenOut(access_token=create_access_token(account.uid, account.email))


@router.post("/login", response_model=TokenOut)
async def login(body: Credentials, session: DbSession) -> TokenOut:
    email = body.email.lower().strip()
    account = (
        await session.execute(select(UserAccount).where(UserAccount.email == email))
    ).scalar_one_or_none()
    if not account or not password_hash.verify(body.password, account.password_hash):
        raise Forbidden("invalid email or password", code="invalid_credentials")
    return TokenOut(access_token=create_access_token(account.uid, account.email))
