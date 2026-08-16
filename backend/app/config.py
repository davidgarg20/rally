from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


def normalize_database_url(value: str) -> str:
    """Accept a standard Neon URL and adapt it for SQLAlchemy + asyncpg."""
    value = value.replace("postgres://", "postgresql://", 1)
    value = value.replace("postgresql://", "postgresql+asyncpg://", 1)
    parsed = urlsplit(value)
    query = dict(parse_qsl(parsed.query, keep_blank_values=True))
    query.pop("channel_binding", None)
    ssl_mode = query.pop("sslmode", None)
    if ssl_mode:
        query["ssl"] = ssl_mode
    return urlunsplit(
        (parsed.scheme, parsed.netloc, parsed.path, urlencode(query), parsed.fragment)
    )


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://rally:rally@localhost:5432/rally"
    firebase_credentials_path: str | None = None
    internal_secret: str = "dev-internal-secret-change-me"
    auth_secret: str = "dev-auth-secret-change-me"
    auth_token_days: int = 30
    cors_origins: str = "http://localhost:3000,https://davidgarg20.github.io"
    env: str = "dev"
    log_level: str = "INFO"

    # Rating engine tuning. Higher beta_margin = blowouts swing ratings more.
    # reference_points anchors the length factor; 21 = standard badminton game.
    beta_margin: float = 0.7
    reference_points: int = 21
    rating_floor: float = 100.0
    initial_rd: float = 350.0
    initial_volatility: float = 0.06

    @field_validator("database_url", mode="before")
    @classmethod
    def _normalize_database_url(cls, value: str) -> str:
        return normalize_database_url(value)


settings = Settings()
