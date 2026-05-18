from typing import Annotated
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.firebase import FirebaseIdentity, verify_id_token
from app.db.base import get_session

DbSession = Annotated[AsyncSession, Depends(get_session)]
CurrentIdentity = Annotated[FirebaseIdentity, Depends(verify_id_token)]
