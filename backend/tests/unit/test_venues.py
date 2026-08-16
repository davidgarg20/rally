from httpx import ASGITransport, AsyncClient

from app.main import create_app


async def test_venues_returns_nearby_bengaluru_courts():
    app = create_app()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/venues?city=BLR")

    assert response.status_code == 200
    venues = response.json()
    assert len(venues) == 5
    assert venues[0]["name"] == "Smash Arena"
    assert venues[0]["distance_km"] == 1.4
    assert venues[0]["hourly_rate"] == 450
    assert venues[0]["rated_night"] == "Saturday"
    assert venues[0]["slots"]


async def test_venues_returns_empty_list_for_unlaunched_city():
    app = create_app()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/venues?city=DEL")

    assert response.status_code == 200
    assert response.json() == []
