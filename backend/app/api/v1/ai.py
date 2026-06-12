# backend/app/api/v1/ai.py
from fastapi import APIRouter, Depends
from app.schemas.ai import ChatRequest
from app.services.ai_service import AiService

router = APIRouter(prefix="/ai", tags=["ai"])

@router.post("/chat")
async def chat(
    request: ChatRequest,
    ai_service: AiService = Depends(AiService)
):
    response_text = await ai_service.chat_completion(request)
    return {"response": response_text}
