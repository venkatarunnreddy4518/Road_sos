import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.models.enums import RequestStatus


class RequestCreate(BaseModel):
    category_id: uuid.UUID
    pickup_lat: float
    pickup_lng: float
    target_helper_id: uuid.UUID | None = None
    note: str | None = None


class StatusUpdate(BaseModel):
    status: RequestStatus  # on_the_way | arrived | completed (validated in service)


class LocationIn(BaseModel):
    latitude: float
    longitude: float


class HelperLocation(BaseModel):
    latitude: float
    longitude: float
    recorded_at: datetime


class ServiceRequestOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    seeker_user_id: uuid.UUID
    category_id: uuid.UUID
    target_helper_id: uuid.UUID | None = None
    helper_id: uuid.UUID | None = None
    status: RequestStatus
    pickup_lat: float
    pickup_lng: float
    note: str | None = None
    fare_amount: float | None = None
    helper_name: str | None = None
    requested_at: datetime
    accepted_at: datetime | None = None
    on_the_way_at: datetime | None = None
    arrived_at: datetime | None = None
    completed_at: datetime | None = None
    cancelled_at: datetime | None = None
    helper_location: HelperLocation | None = None
    seeker_name: str | None = None


class OpenRequestForHelper(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    category_id: uuid.UUID
    status: RequestStatus
    pickup_lat: float
    pickup_lng: float
    note: str | None = None
    requested_at: datetime
    distance_km: float | None = None
    seeker_name: str | None = None
