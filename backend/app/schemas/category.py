import uuid

from app.models.enums import HelperType
from pydantic import BaseModel


class CategoryOut(BaseModel):
    id: uuid.UUID
    key: str
    name: str
    icon: str
    sort_order: int
    helper_types: list[HelperType]
