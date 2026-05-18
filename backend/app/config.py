from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://rally:rally@localhost:5432/rally"
    firebase_credentials_path: str | None = None
    internal_secret: str = "dev-internal-secret-change-me"
    env: str = "dev"
    log_level: str = "INFO"

    # Rating engine tuning. Higher beta_margin = blowouts swing ratings more.
    # reference_points anchors the length factor; 21 = standard badminton game.
    beta_margin: float = 0.7
    reference_points: int = 21
    rating_floor: float = 100.0
    initial_rd: float = 350.0
    initial_volatility: float = 0.06

settings = Settings()
