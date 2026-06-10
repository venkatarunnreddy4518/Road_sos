import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ReviewCreate(BaseModel):
    request_id: uuid.UUID
    rating: int = Field(ge=1, le=5)
    comment: str | None = None


class ReviewOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    request_id: uuid.UUID
    helper_id: uuid.UUID
    seeker_user_id: uuid.UUID
    rating: int
    comment: str | None = None
    created_at: datetime


class HelperReviews(BaseModel):
    rating_avg: float
    rating_count: int
    reviews: list[ReviewOut]
