"""Application configuration loaded from environment (Constitution II: no committed secrets)."""
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/roadside_help"

    jwt_secret: str = "dev-insecure-secret-change-me"
    jwt_algorithm: str = "HS256"
    access_ttl_minutes: int = 60
    refresh_ttl_days: int = 30

    google_client_id: str | None = None
    sms_provider_api_key: str | None = None

    cors_origins: str = "*"

    seed_center_lat: float = 17.4239
    seed_center_lng: float = 78.4738

    @property
    def google_mock_mode(self) -> bool:
        return not self.google_client_id

    @property
    def sms_mock_mode(self) -> bool:
        return not self.sms_provider_api_key

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
