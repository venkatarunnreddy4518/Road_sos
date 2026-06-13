"""FastAPI application entrypoint for the Roadside Help marketplace backend."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import api_router
from app.core.config import settings
from app.core.errors import register_error_handlers
from app.core.logging import configure_logging

configure_logging()

app = FastAPI(
    title="Roadside Help API",
    version="1.0.0",
    description="Two-sided roadside assistance marketplace backend (prototype).",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

register_error_handlers(app)
app.include_router(api_router)

# Auto-create tables for SQLite local dev (no Alembic needed).
if settings.database_url.startswith("sqlite"):
    from app.db.session import create_all_tables
    create_all_tables()


@app.get("/health", tags=["health"])
def health():
    return {
        "status": "ok",
        "google_mock_mode": settings.google_mock_mode,
        "apple_mock_mode": settings.apple_mock_mode,
        "sms_mock_mode": settings.sms_mock_mode,
    }
