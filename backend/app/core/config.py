"""Application configuration loaded from environment (Constitution II: no committed secrets)."""
from functools import lru_cache

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str = "sqlite:///./roadside_help.db"

    @field_validator("database_url", mode="before")
    @classmethod
    def assemble_db_url(cls, v: str) -> str:
        if v and v.startswith("postgresql://"):
            return v.replace("postgresql://", "postgresql+psycopg://", 1)
        return v

    jwt_secret: str = "dev-insecure-secret-change-me"
    jwt_algorithm: str = "HS256"
    access_ttl_minutes: int = 60
    refresh_ttl_days: int = 30

    # Google OAuth: accept one or more client IDs (comma-separated) for ID-token audience checks.
    google_client_id: str | None = None

    # Apple Sign In: Service ID (web) and/or app bundle id(s), comma-separated, used as the
    # ID-token audience. When unset, Apple runs in dev/mock mode.
    apple_client_id: str | None = None

    # Twilio SMS (real OTP delivery). All three required to leave mock mode.
    twilio_account_sid: str | None = None
    twilio_auth_token: str | None = None
    twilio_from_number: str | None = None

    cors_origins: str = "*"

    seed_center_lat: float = 17.4239
    seed_center_lng: float = 78.4738

    @property
    def google_client_ids(self) -> list[str]:
        if not self.google_client_id:
            return []
        return [c.strip() for c in self.google_client_id.split(",") if c.strip()]

    @property
    def google_mock_mode(self) -> bool:
        return not self.google_client_ids

    @property
    def apple_client_ids(self) -> list[str]:
        if not self.apple_client_id:
            return []
        return [c.strip() for c in self.apple_client_id.split(",") if c.strip()]

    @property
    def apple_mock_mode(self) -> bool:
        return not self.apple_client_ids

    @property
    def sms_mock_mode(self) -> bool:
        return not (self.twilio_account_sid and self.twilio_auth_token and self.twilio_from_number)

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
