# backend/app/services/ai_service.py
import httpx
from fastapi import HTTPException
from app.schemas.ai import ChatRequest

class AiService:
    async def chat_completion(self, request: ChatRequest) -> str:
        provider = request.provider.lower()
        if provider == "ollama":
            return await self._chat_ollama(request)
        elif provider in ("openai", "custom"):
            return await self._chat_openai(request)
        elif provider == "gemini":
            return await self._chat_gemini(request)
        elif provider == "anthropic":
            return await self._chat_anthropic(request)
        else:
            raise HTTPException(status_code=400, detail=f"Unsupported AI provider: {request.provider}")

    async def _chat_ollama(self, request: ChatRequest) -> str:
        endpoint = request.endpoint.rstrip("/")
        url = f"{endpoint}/api/chat"
        payload = {
            "model": request.model,
            "messages": [{"role": m.role, "content": m.content} for m in request.messages],
            "stream": False
        }
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json=payload, timeout=30.0)
                response.raise_for_status()
                data = response.json()
                return data["message"]["content"]
            except httpx.HTTPError as e:
                raise HTTPException(status_code=502, detail=f"Ollama connection error: {str(e)}")

    async def _chat_openai(self, request: ChatRequest) -> str:
        endpoint = request.endpoint.rstrip("/")
        url = f"{endpoint}/chat/completions"
        headers = {"Content-Type": "application/json"}
        if request.api_key:
            headers["Authorization"] = f"Bearer {request.api_key}"
        payload = {
            "model": request.model,
            "messages": [{"role": m.role, "content": m.content} for m in request.messages]
        }
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json=payload, headers=headers, timeout=30.0)
                response.raise_for_status()
                data = response.json()
                return data["choices"][0]["message"]["content"]
            except httpx.HTTPError as e:
                raise HTTPException(status_code=502, detail=f"OpenAI connection error: {str(e)}")

    async def _chat_gemini(self, request: ChatRequest) -> str:
        if not request.api_key:
            raise HTTPException(status_code=400, detail="Gemini API Key is required")
        endpoint = request.endpoint.rstrip("/")
        url = f"{endpoint}/v1beta/models/{request.model}:generateContent?key={request.api_key}"
        
        system_instruction = None
        contents = []
        for m in request.messages:
            if m.role == "system":
                system_instruction = m.content
            else:
                role = "model" if m.role == "assistant" else "user"
                contents.append({
                    "role": role,
                    "parts": [{"text": m.content}]
                })
        
        payload = {"contents": contents}
        if system_instruction:
            payload["systemInstruction"] = {
                "parts": [{"text": system_instruction}]
            }

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json=payload, timeout=30.0)
                response.raise_for_status()
                data = response.json()
                return data["candidates"][0]["content"]["parts"][0]["text"]
            except httpx.HTTPError as e:
                raise HTTPException(status_code=502, detail=f"Gemini connection error: {str(e)}")

    async def _chat_anthropic(self, request: ChatRequest) -> str:
        if not request.api_key:
            raise HTTPException(status_code=400, detail="Anthropic API Key is required")
        endpoint = request.endpoint.rstrip("/")
        url = f"{endpoint}/v1/messages"
        
        headers = {
            "x-api-key": request.api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json"
        }
        
        system_prompt = None
        messages = []
        for m in request.messages:
            if m.role == "system":
                system_prompt = m.content
            else:
                messages.append({
                    "role": m.role,
                    "content": m.content
                })
                
        payload = {
            "model": request.model,
            "max_tokens": 1024,
            "messages": messages
        }
        if system_prompt:
            payload["system"] = system_prompt

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json=payload, headers=headers, timeout=30.0)
                response.raise_for_status()
                data = response.json()
                return data["content"][0]["text"]
            except httpx.HTTPError as e:
                raise HTTPException(status_code=502, detail=f"Anthropic connection error: {str(e)}")
