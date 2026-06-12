# backend/tests/unit/test_ai_proxy.py
import pytest
import httpx
from unittest.mock import AsyncMock, MagicMock

@pytest.mark.asyncio
async def test_ai_chat_ollama(client, monkeypatch):
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "message": {"content": "Ollama local response"}
    }
    
    # Mock httpx.AsyncClient.post
    monkeypatch.setattr(httpx.AsyncClient, "post", AsyncMock(return_value=mock_response))

    payload = {
        "messages": [
            {"role": "user", "content": "Hello Ollama"}
        ],
        "provider": "ollama",
        "endpoint": "http://localhost:11434",
        "model": "llama3.2"
    }

    res = client.post("/api/v1/ai/chat", json=payload)
    assert res.status_code == 200
    assert res.json() == {"response": "Ollama local response"}


@pytest.mark.asyncio
async def test_ai_chat_openai(client, monkeypatch):
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "choices": [
            {"message": {"content": "OpenAI cloud response"}}
        ]
    }
    
    monkeypatch.setattr(httpx.AsyncClient, "post", AsyncMock(return_value=mock_response))

    payload = {
        "messages": [
            {"role": "system", "content": "You are a mechanic"},
            {"role": "user", "content": "Hello OpenAI"}
        ],
        "provider": "openai",
        "endpoint": "https://api.openai.com/v1",
        "model": "gpt-4o-mini",
        "api_key": "test-key"
    }

    res = client.post("/api/v1/ai/chat", json=payload)
    assert res.status_code == 200
    assert res.json() == {"response": "OpenAI cloud response"}


@pytest.mark.asyncio
async def test_ai_chat_gemini(client, monkeypatch):
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "candidates": [
            {
                "content": {
                    "parts": [{"text": "Gemini cloud response"}]
                }
            }
        ]
    }
    
    monkeypatch.setattr(httpx.AsyncClient, "post", AsyncMock(return_value=mock_response))

    payload = {
        "messages": [
            {"role": "system", "content": "You are a mechanic"},
            {"role": "user", "content": "Hello Gemini"}
        ],
        "provider": "gemini",
        "endpoint": "https://generativelanguage.googleapis.com",
        "model": "gemini-1.5-flash",
        "api_key": "test-gemini-key"
    }

    res = client.post("/api/v1/ai/chat", json=payload)
    assert res.status_code == 200
    assert res.json() == {"response": "Gemini cloud response"}


@pytest.mark.asyncio
async def test_ai_chat_anthropic(client, monkeypatch):
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "content": [{"text": "Claude cloud response"}]
    }
    
    monkeypatch.setattr(httpx.AsyncClient, "post", AsyncMock(return_value=mock_response))

    payload = {
        "messages": [
            {"role": "system", "content": "You are a mechanic"},
            {"role": "user", "content": "Hello Claude"}
        ],
        "provider": "anthropic",
        "endpoint": "https://api.anthropic.com",
        "model": "claude-3-5-sonnet",
        "api_key": "test-claude-key"
    }

    res = client.post("/api/v1/ai/chat", json=payload)
    assert res.status_code == 200
    assert res.json() == {"response": "Claude cloud response"}
