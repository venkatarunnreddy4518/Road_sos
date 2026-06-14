"""Service category and helper-profile (supply-side) models."""
import uuid
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    Enum,
    Float,
    ForeignKey,
    Integer,
    JSON,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, uuid_pk
from app.models.enums import DataSource, HelperType


class ServiceCategory(Base):
    __tablename__ = "service_categories"

    id: Mapped[uuid.UUID] = uuid_pk()
    key: Mapped[str] = mapped_column(String(40), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    icon: Mapped[str] = mapped_column(String(40), nullable=False, default="build")
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    # Base service fee (INR) used as the request fare when a job completes.
    base_fare: Mapped[Decimal] = mapped_column(Numeric(8, 2), default=0, nullable=False)

    helper_types: Mapped[list["CategoryHelperType"]] = relationship(
        back_populates="category", cascade="all, delete-orphan"
    )


class CategoryHelperType(Base):
    __tablename__ = "category_helper_types"
    __table_args__ = (UniqueConstraint("category_id", "helper_type", name="uq_category_helper_type"),)

    category_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("service_categories.id", ondelete="CASCADE"), primary_key=True
    )
    helper_type: Mapped[HelperType] = mapped_column(
        Enum(HelperType, name="helper_type", native_enum=False), primary_key=True
    )

    category: Mapped["ServiceCategory"] = relationship(back_populates="helper_types")


class HelperProfile(Base, TimestampMixin):
    __tablename__ = "helper_profiles"

    id: Mapped[uuid.UUID] = uuid_pk()
    owner_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    helper_type: Mapped[HelperType] = mapped_column(
        Enum(HelperType, name="helper_type", native_enum=False), index=True
    )
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    sms_capable: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    latitude: Mapped[float] = mapped_column(Float, index=True, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, index=True, nullable=False)
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
    opening_hours: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    data_source: Mapped[DataSource] = mapped_column(
        Enum(DataSource, name="data_source", native_enum=False), default=DataSource.curated, nullable=False
    )
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    rating_avg: Mapped[float] = mapped_column(Numeric(2, 1), default=0, nullable=False)
    rating_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
