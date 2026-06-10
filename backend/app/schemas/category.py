import uuid

from pydantic import BaseModel

from app.models.enums import HelperType


class CategoryOut(BaseModel):
    id: uuid.UUID
    key: str
    name: str
    icon: str
    sort_order: int
    helper_types: list[HelperType]
