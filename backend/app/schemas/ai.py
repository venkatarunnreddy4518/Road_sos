# backend/app/schemas/ai.py
from pydantic import BaseModel
from typing import List, Optional

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    # Server-side defaults: the AI works out-of-the-box via local Ollama even if the
    # client sends only messages. Clients may override to use a hosted provider + key.
    provider: str = "ollama"
    endpoint: str = "http://localhost:11434"
    model: str = "llama3.2"
    api_key: Optional[str] = None
