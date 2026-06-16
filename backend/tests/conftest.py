"""Pytest fixtures. Requires a reachable PostgreSQL (TEST_DATABASE_URL or DATABASE_URL).

Each test runs against a freshly created schema and is cleaned up afterwards.
"""

import os

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ensure config picks up a test DB before app modules import settings.
os.environ.setdefault(
    "DATABASE_URL",
    os.environ.get("TEST_DATABASE_URL", "sqlite:///./roadside_help_test.db"),
)

# Force deterministic provider behaviour (mock/dev mode) regardless of the
# developer's local .env, so tests don't break when real credentials are present.
for _provider_var in (
    "GOOGLE_CLIENT_ID",
    "APPLE_CLIENT_ID",
    "TWILIO_ACCOUNT_SID",
    "TWILIO_AUTH_TOKEN",
    "TWILIO_FROM_NUMBER",
):
    os.environ[_provider_var] = ""

from app.db.session import get_db  # noqa: E402
from app.main import app  # noqa: E402
from app.models import Base  # noqa: E402

ENGINE = create_engine(os.environ["DATABASE_URL"], future=True)
TestSession = sessionmaker(bind=ENGINE, autoflush=False, autocommit=False, future=True)


@pytest.fixture(scope="session")
def _schema():
    """Create the schema once for DB-backed tests. Pure-unit tests don't request this."""
    Base.metadata.drop_all(ENGINE)
    Base.metadata.create_all(ENGINE)
    yield
    Base.metadata.drop_all(ENGINE)


@pytest.fixture
def _clean_tables(_schema):
    yield
    with ENGINE.begin() as conn:
        for table in reversed(Base.metadata.sorted_tables):
            conn.exec_driver_sql(f'DELETE FROM "{table.name}"')


@pytest.fixture
def db(_schema, _clean_tables):
    session = TestSession()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def client(_schema, _clean_tables):
    def _override():
        session = TestSession()
        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_db] = _override
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


@pytest.fixture
def seed_categories(db):
    from app.seed.run import seed

    seed()
    return db
