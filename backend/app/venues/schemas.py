from __future__ import annotations

from pydantic import BaseModel


class VenueOut(BaseModel):
    id: str
    name: str
    area: str
    city: str
    distance_km: float
    courts: int
    hourly_rate: int
    players_at_level: int
    rated_night: str | None
    slots: list[str]
