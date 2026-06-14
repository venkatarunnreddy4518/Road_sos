"""add base_fare to categories and fare_amount to requests

Revision ID: 0002_request_fare_helper
Revises: 0001_initial
Create Date: 2026-06-14
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0002_request_fare_helper"
down_revision: Union[str, None] = "0001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Category base fee used as the request fare on completion (INR).
    op.add_column(
        "service_categories",
        sa.Column("base_fare", sa.Numeric(8, 2), nullable=False, server_default="0"),
    )
    # Final fare stamped onto a request when the job completes.
    op.add_column(
        "service_requests",
        sa.Column("fare_amount", sa.Numeric(8, 2), nullable=True),
    )
    # Drop the server default now that existing rows are backfilled; the ORM
    # supplies the value going forward (re-seeded with real per-category fares).
    op.alter_column("service_categories", "base_fare", server_default=None)


def downgrade() -> None:
    op.drop_column("service_requests", "fare_amount")
    op.drop_column("service_categories", "base_fare")
