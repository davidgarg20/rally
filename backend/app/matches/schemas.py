from __future__ import annotations
from datetime import datetime
from pydantic import BaseModel, Field


class GameIn(BaseModel):
    game_no: int = Field(ge=1, le=5)
    team1_points: int = Field(ge=0, le=30)
    team2_points: int = Field(ge=0, le=30)


class MatchSubmit(BaseModel):
    format: str = Field(pattern="^[SD]$")
    played_at: datetime
    venue: str | None = None
    team1_phones: list[str]
    team2_phones: list[str]
    games: list[GameIn]


class ParticipantOut(BaseModel):
    player_id: str | None
    phone_e164: str
    display_name: str | None
    team: int
    is_submitter: bool
    confirmed: bool
    disputed: bool


class GameOut(BaseModel):
    game_no: int
    team1_points: int
    team2_points: int


class RatingDeltaOut(BaseModel):
    player_id: str
    rating_before: float
    rating_after: float


class MatchOut(BaseModel):
    id: str
    format: str
    played_at: datetime
    venue: str | None
    status: str
    validation_deadline: datetime
    validated_at: datetime | None
    participants: list[ParticipantOut]
    games: list[GameOut]
    rating_deltas: list[RatingDeltaOut]
