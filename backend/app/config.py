from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://rally:rally@localhost:5432/rally"
    firebase_credentials_path: str | None = None
    internal_secret: str = "dev-internal-secret-change-me"
    env: str = "dev"
    log_level: str = "INFO"

settings = Settings()
