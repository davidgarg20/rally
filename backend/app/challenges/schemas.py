from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class ChallengeCreate(BaseModel):
    opponent_username: str = Field(min_length=3, max_length=20)


class ChallengePlayerOut(BaseModel):
    id: str
    username: str
    display_name: str
    rating: float


class ChallengeOut(BaseModel):
    id: str
    status: str
    created_at: datetime
    responded_at: datetime | None
    challenger: ChallengePlayerOut
    challenged: ChallengePlayerOut
