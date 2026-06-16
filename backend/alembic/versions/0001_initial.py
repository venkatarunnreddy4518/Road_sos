"""initial schema — create all tables from ORM metadata

Revision ID: 0001_initial
Revises:
Create Date: 2026-06-10
"""

from typing import Sequence, Union

from alembic import op
from app.models import Base

revision: str = "0001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Baseline migration: create the full normalized schema (tables + PG enum types
    # + indexes + constraints) directly from the SQLAlchemy ORM metadata.
    Base.metadata.create_all(bind=op.get_bind())


def downgrade() -> None:
    Base.metadata.drop_all(bind=op.get_bind())
