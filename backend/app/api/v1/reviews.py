from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.review import ReviewCreate, ReviewOut
from app.services import review_service
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

router = APIRouter(prefix="/reviews", tags=["reviews"])


@router.post("", response_model=ReviewOut, status_code=201)
def create_review(
    body: ReviewCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)
):
    return review_service.create_review(db, user, body.request_id, body.rating, body.comment)
