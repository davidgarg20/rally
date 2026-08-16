from app.config import normalize_database_url


def test_neon_database_url_is_normalized_for_asyncpg() -> None:
    url = (
        "postgresql://rally:secret@example.neon.tech/rally"
        "?sslmode=require&channel_binding=require"
    )

    assert normalize_database_url(url) == (
        "postgresql+asyncpg://rally:secret@example.neon.tech/rally?ssl=require"
    )
