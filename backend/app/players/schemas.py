from __future__ import annotations
from datetime import date
from pydantic import BaseModel, Field

class PlayerCreate(BaseModel):
    display_name: str = Field(min_length=1, max_length=80)
    gender: str | None = Field(default=None, pattern="^[MFO]$")
    dob: date | None = None
    home_city: str = "BLR"

class PlayerUpdate(BaseModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=80)
    gender: str | None = Field(default=None, pattern="^[MFO]$")
    dob: date | None = None
    home_city: str | None = None

class RatingOut(BaseModel):
    format: str
    rating: float
    rd: float
    matches_played: int

class PlayerOut(BaseModel):
    id: str
    phone_e164: str
    display_name: str
    gender: str | None
    dob: date | None
    home_city: str
    ratings: list[RatingOut]
