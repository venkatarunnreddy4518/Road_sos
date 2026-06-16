from app.db.session import get_db
from app.schemas.category import CategoryOut
from app.services import category_service
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db)):
    return category_service.list_categories(db)
