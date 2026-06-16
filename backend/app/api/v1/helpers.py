import uuid
from datetime import datetime, timezone

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.enums import HelperType
from app.models.user import User
from app.schemas.helper import HelperOut, HelperSyncFeed, HelperUpsert, HelperWithDistance
from app.schemas.review import HelperReviews
from app.services import helper_service, review_service
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

router = APIRouter(prefix="/helpers", tags=["helpers"])


@router.get("/nearby", response_model=list[HelperWithDistance])
def nearby(
    lat: float = Query(...),
    lng: float = Query(...),
    category: str | None = None,
    helper_type: HelperType | None = None,
    limit: int = Query(3, ge=1, le=50),
    db: Session = Depends(get_db),
):
    return helper_service.nearby(db, lat, lng, category, helper_type, limit)


@router.get("/search", response_model=list[HelperWithDistance])
def search(
    q: str = Query(..., min_length=1),
    lat: float | None = None,
    lng: float | None = None,
    limit: int = Query(20, ge=1, le=50),
    db: Session = Depends(get_db),
):
    return helper_service.search(db, q, lat, lng, limit)


@router.get("", response_model=HelperSyncFeed)
def sync_feed(
    updated_since: datetime | None = None,
    limit: int = Query(500, ge=1, le=2000),
    db: Session = Depends(get_db),
):
    helpers = helper_service.sync_feed(db, updated_since, limit)
    return {
        "helpers": helpers,
        "synced_at": datetime.now(timezone.utc).isoformat(),
        "next_cursor": None,
    }


@router.get("/{helper_id}/reviews", response_model=HelperReviews)
def reviews(helper_id: uuid.UUID, db: Session = Depends(get_db)):
    return review_service.helper_reviews(db, helper_id)


@router.get("/{helper_id}", response_model=HelperOut)
def get_helper(helper_id: uuid.UUID, db: Session = Depends(get_db)):
    return helper_service.get_by_id(db, helper_id)


@router.post("", response_model=HelperOut, status_code=201)
def upsert_helper(
    body: HelperUpsert, db: Session = Depends(get_db), user: User = Depends(get_current_user)
):
    return helper_service.upsert_for_owner(db, user, body.model_dump())
