from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.user import ProfileUpdate, UserOut
from app.services import profile_service

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("", response_model=UserOut)
def get_profile(user: User = Depends(get_current_user)):
    return user


@router.patch("", response_model=UserOut)
def update_profile(
    body: ProfileUpdate, db: Session = Depends(get_db), user: User = Depends(get_current_user)
):
    return profile_service.update_profile(db, user, body.model_dump(exclude_unset=True))
