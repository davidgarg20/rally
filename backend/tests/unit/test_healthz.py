from httpx import ASGITransport, AsyncClient

from app.main import create_app


async def test_healthz_returns_ok():
    app = create_app()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        resp = await ac.get("/healthz")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


async def test_github_pages_origin_is_allowed():
    app = create_app()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        resp = await ac.options(
            "/auth/login",
            headers={
                "Origin": "https://davidgarg20.github.io",
                "Access-Control-Request-Method": "POST",
            },
        )
    assert resp.status_code == 200
    assert resp.headers["access-control-allow-origin"] == "https://davidgarg20.github.io"
