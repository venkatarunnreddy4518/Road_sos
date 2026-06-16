import uuid

from app.models.enums import DataSource, HelperType
from pydantic import BaseModel, ConfigDict, Field


class HelperBase(BaseModel):
    name: str
    helper_type: HelperType
    phone: str | None = None
    sms_capable: bool = False
    latitude: float
    longitude: float
    address: str | None = None
    opening_hours: dict | None = None


class HelperOut(HelperBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    data_source: DataSource
    is_verified: bool
    rating_avg: float
    rating_count: int


class HelperWithDistance(HelperOut):
    distance_km: float
    is_far: bool
    open_now: bool | None = None  # null => hours unknown


class HelperUpsert(BaseModel):
    name: str = Field(min_length=1, max_length=160)
    helper_type: HelperType
    phone: str | None = None
    sms_capable: bool = False
    latitude: float
    longitude: float
    address: str | None = None
    opening_hours: dict | None = None


class HelperSyncFeed(BaseModel):
    helpers: list[HelperOut]
    synced_at: str
    next_cursor: str | None = None
