# backend/app/schemas/ai.py
from pydantic import BaseModel
from typing import List, Optional

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    provider: str
    endpoint: str
    model: str
    api_key: Optional[str] = None
