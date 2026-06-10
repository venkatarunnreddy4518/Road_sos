import uuid

from pydantic import BaseModel, ConfigDict, EmailStr


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    display_name: str
    email: EmailStr | None = None
    phone: str | None = None
    vehicle_info: str | None = None
    is_helper: bool
    preferred_language: str


class ProfileUpdate(BaseModel):
    display_name: str | None = None
    phone: str | None = None
    vehicle_info: str | None = None
    preferred_language: str | None = None
