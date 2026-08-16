from __future__ import annotations

from fastapi import APIRouter, Query

from app.venues.schemas import VenueOut

router = APIRouter(prefix="/venues", tags=["venues"])

_VENUES = (
    VenueOut(
        id="smash-arena",
        name="Smash Arena",
        area="HSR Layout · Sector 2",
        city="BLR",
        distance_km=1.4,
        courts=6,
        hourly_rate=450,
        players_at_level=18,
        rated_night="Saturday",
        slots=["Today, 7:30 PM", "Today, 9:00 PM", "Tomorrow, 8:00 PM"],
    ),
    VenueOut(
        id="padukone-dravid-centre",
        name="Padukone-Dravid Centre",
        area="Koramangala",
        city="BLR",
        distance_km=2.1,
        courts=12,
        hourly_rate=600,
        players_at_level=34,
        rated_night="Thursday",
        slots=["Today, 8:00 PM", "Tomorrow, 6:30 AM", "Tomorrow, 7:30 PM"],
    ),
    VenueOut(
        id="nimbus-badminton-club",
        name="Nimbus Badminton Club",
        area="Koramangala 5th Block",
        city="BLR",
        distance_km=3.2,
        courts=8,
        hourly_rate=400,
        players_at_level=11,
        rated_night=None,
        slots=["Today, 9:00 PM", "Tomorrow, 7:00 AM", "Tuesday, 8:00 PM"],
    ),
    VenueOut(
        id="play-arena",
        name="Play Arena",
        area="Sarjapur Road",
        city="BLR",
        distance_km=4.8,
        courts=10,
        hourly_rate=550,
        players_at_level=9,
        rated_night=None,
        slots=["Tomorrow, 6:30 AM", "Tomorrow, 9:00 PM", "Wednesday, 8:00 PM"],
    ),
    VenueOut(
        id="shuttle-hub",
        name="Shuttle Hub",
        area="Indiranagar",
        city="BLR",
        distance_km=6.4,
        courts=5,
        hourly_rate=500,
        players_at_level=14,
        rated_night="Tuesday",
        slots=["Tuesday, 7:00 PM", "Tuesday, 8:30 PM", "Thursday, 7:30 PM"],
    ),
)


@router.get("", response_model=list[VenueOut])
async def list_venues(
    city: str = Query(default="BLR", min_length=2, max_length=8),
) -> list[VenueOut]:
    """Return nearby Rally venues ordered by distance for a city."""
    city_code = city.upper().strip()
    return [venue for venue in _VENUES if venue.city == city_code]
