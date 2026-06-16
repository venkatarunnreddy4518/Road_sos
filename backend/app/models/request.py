"""Service request lifecycle, live location updates, and reviews."""

import uuid
from datetime import datetime
from decimal import Decimal

from app.db.base import Base, TimestampMixin, uuid_pk
from app.models.enums import RequestStatus
from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column


class ServiceRequest(Base, TimestampMixin):
    __tablename__ = "service_requests"

    id: Mapped[uuid.UUID] = uuid_pk()
    seeker_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    category_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("service_categories.id"), nullable=False
    )
    target_helper_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("helper_profiles.id"), nullable=True
    )
    helper_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("helper_profiles.id"), nullable=True, index=True
    )
    status: Mapped[RequestStatus] = mapped_column(
        Enum(RequestStatus, name="request_status", native_enum=False),
        default=RequestStatus.requested,
        nullable=False,
    )
    pickup_lat: Mapped[float] = mapped_column(Float, nullable=False)
    pickup_lng: Mapped[float] = mapped_column(Float, nullable=False)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Final fare (INR), set from the category base fare when the job completes.
    fare_amount: Mapped[Decimal | None] = mapped_column(Numeric(8, 2), nullable=True)

    requested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    on_the_way_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    arrived_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    cancelled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    cancelled_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )


class HelperLocationUpdate(Base):
    __tablename__ = "helper_location_updates"
    __table_args__ = (Index("ix_loc_request_recorded", "request_id", "recorded_at"),)

    id: Mapped[uuid.UUID] = uuid_pk()
    request_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("service_requests.id", ondelete="CASCADE"), nullable=False
    )
    helper_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("helper_profiles.id"), nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class Review(Base):
    __tablename__ = "reviews"
    __table_args__ = (CheckConstraint("rating >= 1 AND rating <= 5", name="ck_rating_range"),)

    id: Mapped[uuid.UUID] = uuid_pk()
    request_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("service_requests.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    helper_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("helper_profiles.id"), nullable=False, index=True
    )
    seeker_user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    rating: Mapped[int] = mapped_column(Integer, nullable=False)
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
