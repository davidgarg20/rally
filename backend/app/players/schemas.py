from __future__ import annotations
from datetime import date
from pydantic import BaseModel, Field

_USERNAME_PATTERN = r"^[a-z][a-z0-9_]{2,19}$"


class PlayerCreate(BaseModel):
    username: str = Field(pattern=_USERNAME_PATTERN, min_length=3, max_length=20)
    display_name: str = Field(min_length=1, max_length=80)
    gender: str | None = Field(default=None, pattern="^[MFO]$")
    dob: date | None = None
    home_city: str = "BLR"


class PlayerUpdate(BaseModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=80)
    gender: str | None = Field(default=None, pattern="^[MFO]$")
    dob: date | None = None
    home_city: str | None = None


class PlayerOut(BaseModel):
    id: str
    phone_e164: str
    username: str
    display_name: str
    gender: str | None
    dob: date | None
    home_city: str
    rating: float
    rd: float
    matches_played: int


class PublicPlayerOut(BaseModel):
    """Public profile — no phone, no DOB. Anyone authenticated can read this."""
    id: str
    username: str
    display_name: str
    gender: str | None
    home_city: str
    rating: float
    rd: float
    matches_played: int
    rank: int | None  # 1-based rank in their city; null if not yet ranked


class HeadToHeadOut(BaseModel):
    me_wins: int
    opponent_wins: int
    last_matches: list  # list[MatchOut]; avoiding circular import
