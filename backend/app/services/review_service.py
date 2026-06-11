"""Reviews: one per completed request, no self-review, recompute helper aggregate."""
import uuid
from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.errors import AppError
from app.models.enums import RequestStatus
from app.models.helper import HelperProfile
from app.models.request import Review, ServiceRequest
from app.models.user import User


def create_review(db: Session, seeker: User, request_id: uuid.UUID, rating: int, comment: str | None) -> Review:
    if rating < 1 or rating > 5:
        raise AppError("validation_error", "Rating must be between 1 and 5.", status_code=422)
    req = db.get(ServiceRequest, request_id)
    if not req:
        raise AppError("not_found", "Request not found.", status_code=404)
    if req.seeker_user_id != seeker.id:
        raise AppError("forbidden", "Only the seeker can review this request.", status_code=403)
    if req.status != RequestStatus.completed:
        raise AppError("validation_error", "Request is not completed.", status_code=422)
    if not req.helper_id:
        raise AppError("validation_error", "Request has no assigned helper.", status_code=422)
    if db.scalar(select(Review).where(Review.request_id == request_id)):
        raise AppError("conflict", "Request already reviewed.", status_code=409)
    helper = db.get(HelperProfile, req.helper_id)
    if helper.owner_user_id == seeker.id:
        raise AppError("validation_error", "You cannot review your own service.", status_code=422)

    review = Review(
        request_id=request_id,
        helper_id=req.helper_id,
        seeker_user_id=seeker.id,
        rating=rating,
        comment=comment,
        created_at=datetime.now(timezone.utc).replace(tzinfo=None),
    )
    db.add(review)
    db.flush()
    _recompute_aggregate(db, req.helper_id)
    db.commit()
    db.refresh(review)
    return review


def _recompute_aggregate(db: Session, helper_id: uuid.UUID) -> None:
    avg, count = db.execute(
        select(func.avg(Review.rating), func.count(Review.id)).where(Review.helper_id == helper_id)
    ).one()
    helper = db.get(HelperProfile, helper_id)
    helper.rating_avg = round(float(avg), 1) if avg is not None else 0
    helper.rating_count = int(count)


def helper_reviews(db: Session, helper_id: uuid.UUID) -> dict:
    helper = db.get(HelperProfile, helper_id)
    if not helper:
        raise AppError("not_found", "Helper not found.", status_code=404)
    reviews = list(
        db.scalars(select(Review).where(Review.helper_id == helper_id).order_by(Review.created_at.desc()))
    )
    return {"rating_avg": float(helper.rating_avg), "rating_count": helper.rating_count, "reviews": reviews}
