"""Database engine + session factory."""

from collections.abc import Generator

from app.core.config import settings
from sqlalchemy import create_engine, event
from sqlalchemy.orm import Session, sessionmaker

_is_sqlite = settings.database_url.startswith("sqlite")

connect_args = {"check_same_thread": False} if _is_sqlite else {}

# SQLite (local dev) uses the default pool; Postgres uses a QueuePool sized to serve
# ~50 concurrent members (pool_size + max_overflow) without stalling on connections.
pool_kwargs = (
    {}
    if _is_sqlite
    else {
        "pool_size": settings.db_pool_size,
        "max_overflow": settings.db_max_overflow,
        "pool_timeout": settings.db_pool_timeout,
        "pool_recycle": settings.db_pool_recycle,
    }
)

engine = create_engine(
    settings.database_url,
    pool_pre_ping=not _is_sqlite,
    future=True,
    connect_args=connect_args,
    **pool_kwargs,
)

# Enable WAL mode and foreign keys for SQLite
if _is_sqlite:

    @event.listens_for(engine, "connect")
    def _set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA journal_mode=WAL")
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()


SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_all_tables():
    """Create all tables (useful for SQLite local dev without Alembic migrations)."""
    import app.models.helper  # noqa: F401
    import app.models.request  # noqa: F401

    # Import all models so they register with Base.metadata
    import app.models.user  # noqa: F401
    from app.db.base import Base

    Base.metadata.create_all(bind=engine)
