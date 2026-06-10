"""PostgreSQL enum types used across models."""
import enum


class AuthProvider(str, enum.Enum):
    phone = "phone"
    email = "email"
    google = "google"


class HelperType(str, enum.Enum):
    puncture_shop = "puncture_shop"
    petrol_pump = "petrol_pump"
    mechanic = "mechanic"
    towing = "towing"
    battery = "battery"


class DataSource(str, enum.Enum):
    curated = "curated"
    third_party = "third_party"


class RequestStatus(str, enum.Enum):
    requested = "requested"
    accepted = "accepted"
    on_the_way = "on_the_way"
    arrived = "arrived"
    completed = "completed"
    cancelled = "cancelled"
