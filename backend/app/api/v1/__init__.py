"""v1 API router aggregation."""
from fastapi import APIRouter

from app.api.v1 import auth, categories, helpers, profile, requests, reviews, ai

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth.router)
api_router.include_router(profile.router)
api_router.include_router(categories.router)
api_router.include_router(helpers.router)
api_router.include_router(requests.router)
api_router.include_router(reviews.router)
api_router.include_router(ai.router)
