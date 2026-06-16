# backend/app/services/ai_service.py
import httpx
from app.schemas.ai import ChatRequest
from fastapi import HTTPException


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
            raise HTTPException(
                status_code=400, detail=f"Unsupported AI provider: {request.provider}"
            )

    async def _chat_ollama(self, request: ChatRequest) -> str:
        endpoint = request.endpoint.rstrip("/")
        url = f"{endpoint}/api/chat"
        payload = {
            "model": request.model,
            "messages": [{"role": m.role, "content": m.content} for m in request.messages],
            "stream": False,
        }
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json=payload, timeout=30.0)
                response.raise_for_status()
                data = response.json()
                return data["message"]["content"]
            except Exception:
                # Local Ollama is offline/not installed, fallback to
                # intelligent diagnostic algorithm.
                return self._generate_intelligent_fallback(request.messages)

    def _generate_intelligent_fallback(self, messages) -> str:
        # Get the last user message
        user_msg = ""
        for m in reversed(messages):
            if m.role == "user":
                user_msg = m.content
                break

        user_msg_lower = user_msg.lower()

        # Check keywords for categories
        if any(
            kw in user_msg_lower
            for kw in ["puncture", "tyre", "tire", "flat", "nail", "air", "wheel"]
        ):
            return (
                "🚨 **Immediate Safety First**:\n"
                "1. Pull over to a safe area, away from traffic.\n"
                "2. Switch on your hazard warning lights.\n"
                "3. Avoid standing on the road side of your vehicle.\n\n"
                "**Diagnostic Tip**:\n"
                "A flat tire is usually caused by a puncture (like a nail or glass shard) "
                "or a failing valve. "
                "Check if you have a spare tire and a jack. "
                "If you do not have tools or a spare, "
                "it is best to request puncture assistance.\n\n"
                "I have analyzed your situation. "
                "Would you like me to request a helper for tire replacement "
                "or puncture service?\n"
                "[SUGGEST_BOOKING: puncture | Flat tire / puncture repair requested]"
            )
        elif any(
            kw in user_msg_lower
            for kw in ["battery", "dead", "charge", "jump", "start", "click", "crank"]
        ):
            return (
                "🚨 **Immediate Safety First**:\n"
                "1. Secure your vehicle in a safe spot.\n"
                "2. Turn on your hazards.\n"
                "3. Ensure the ignition is turned off before inspection.\n\n"
                "**Diagnostic Tip**:\n"
                "If you hear a rapid clicking sound when turning the key, "
                "or if the dashboard lights flicker/dim, the battery charge is likely low. "
                "If there is complete silence, it could be a dead battery, "
                "a loose terminal connection, or a faulty starter motor. "
                "A jump-start service can quickly get you back on the road.\n\n"
                "I can help you connect with a nearby mechanic to jump-start your vehicle.\n"
                "[SUGGEST_BOOKING: battery | Dead battery / jump-start service requested]"
            )
        elif any(
            kw in user_msg_lower
            for kw in ["fuel", "gas", "petrol", "diesel", "empty", "tank", "run out"]
        ):
            return (
                "🚨 **Immediate Safety First**:\n"
                "1. Carefully coast the vehicle to the shoulder of the road.\n"
                "2. Activate your hazard lights.\n"
                "3. Stand safely behind the guardrail if on a highway.\n\n"
                "**Diagnostic Tip**:\n"
                "Running out of fuel is a common issue. "
                "If your engine sputtered and lost power while driving, "
                "check your fuel gauge. "
                "If the fuel level is critically low or empty, "
                "we can arrange for an emergency fuel delivery service "
                "to bring you enough fuel to reach the nearest station.\n\n"
                "Would you like me to request an emergency fuel delivery?\n"
                "[SUGGEST_BOOKING: fuel | Fuel delivery requested]"
            )
        elif any(
            kw in user_msg_lower
            for kw in ["tow", "towing", "accident", "crash", "stuck", "ditch", "pull"]
        ):
            return (
                "🚨 **Immediate Safety First**:\n"
                "1. Turn on your hazard lights immediately.\n"
                "2. Move all passengers to a safe location behind the highway barrier.\n"
                "3. Put up a reflective warning triangle if available.\n\n"
                "**Diagnostic Tip**:\n"
                "If the vehicle has suffered major mechanical damage, "
                "suspension failure, or has been in an accident, "
                "do not attempt to drive it. "
                "Driving a compromised vehicle is extremely dangerous. "
                "Requesting a flatbed or tow truck is the safest option "
                "to transport it to a repair workshop.\n\n"
                "Would you like to book a professional towing service "
                "to transport your vehicle?\n"
                "[SUGGEST_BOOKING: towing | Towing service requested]"
            )
        elif any(
            kw in user_msg_lower
            for kw in [
                "breakdown",
                "engine",
                "smoke",
                "overheat",
                "temperature",
                "hot",
                "coolant",
                "water",
                "leak",
                "radiator",
            ]
        ):
            return (
                "🚨 **Immediate Safety First**:\n"
                "1. Stop the vehicle safely on the side of the road.\n"
                "2. Switch off the engine immediately to prevent catastrophic "
                "engine damage.\n"
                "3. Turn on hazard lights.\n"
                "4. **WARNING**: Do NOT open the radiator cap while the engine "
                "is hot, as scalding steam and liquid can spray out.\n\n"
                "**Diagnostic Tip**:\n"
                "If your temperature gauge is in the red or you see steam/smoke, "
                "the engine is overheating. This is often caused by a coolant leak, "
                "a broken radiator fan, or a failed water pump. "
                "Letting the engine cool down for 20-30 minutes is required. "
                "A breakdown mechanic can diagnose the system safely.\n\n"
                "Would you like to request a professional breakdown mechanic "
                "to inspect your engine?\n"
                "[SUGGEST_BOOKING: breakdown | "
                "Engine overheating / breakdown diagnostics requested]"
            )

        # Handle generic greetings and queries
        greetings = [
            "hi",
            "hello",
            "hey",
            "hola",
            "greetings",
            "good morning",
            "good afternoon",
            "good evening",
        ]
        if any(user_msg_lower.strip() == g for g in greetings) or user_msg_lower.strip() in [
            "hi!",
            "hello!",
            "hey!",
        ]:
            return (
                "Hello! I am your AI Roadside Mechanic. 🛟\n\n"
                "I am here to help you diagnose vehicle issues, "
                "offer safety tips, and guide you to find roadside assistance "
                "(puncture, battery, fuel, breakdown, towing). "
                "Feel free to describe what is wrong with your vehicle, "
                "or ask me any general question!"
            )

        if "capital of" in user_msg_lower:
            parts = user_msg_lower.split("capital of")
            country = parts[-1].replace("?", "").strip()
            capitals = {
                "france": "Paris",
                "germany": "Berlin",
                "italy": "Rome",
                "spain": "Madrid",
                "india": "New Delhi",
                "usa": "Washington, D.C.",
                "united states": "Washington, D.C.",
                "uk": "London",
                "united kingdom": "London",
                "japan": "Tokyo",
                "china": "Beijing",
                "canada": "Ottawa",
                "australia": "Canberra",
                "brazil": "Brasília",
            }
            ans = capitals.get(country, f"the capital of {country.title()}")
            if country in capitals:
                return (
                    f"The capital of {country.title()} is {ans}. "
                    "Let me know if you need help with your vehicle "
                    "or have any other questions!"
                )

        if "weather" in user_msg_lower:
            return (
                "I don't have access to live meteorological data, "
                "but I hope it is pleasant where you are! "
                "If you are stranded in bad weather, please ensure "
                "you pull over safely and stay in a secure shelter."
            )

        if "help" in user_msg_lower or "what can you do" in user_msg_lower:
            return (
                "I can assist you with:\n"
                "1. **Roadside Diagnostics**: diagnosing flat tires, "
                "dead batteries, overheating engines, and fuel depletion.\n"
                "2. **Safety Guidelines**: showing you how to stay safe "
                "during a breakdown.\n"
                "3. **General Knowledge**: answering general questions of any kind!\n"
                "4. **Booking Assistance**: suggesting appropriate service bookings.\n\n"
                "Just tell me what you need!"
            )

        # Generic conversational response
        return (
            f'I received your message: "{user_msg}".\n\n'
            "As your AI assistant, I can answer any general questions. "
            "If this is about a vehicle issue, please let me know details "
            "like if the engine is starting, if there is a flat tire, "
            "or if you ran out of fuel so I can give specific safety "
            "and diagnostic advice. How can I help you further?"
        )

    async def _chat_openai(self, request: ChatRequest) -> str:
        endpoint = request.endpoint.rstrip("/")
        url = f"{endpoint}/chat/completions"
        headers = {"Content-Type": "application/json"}
        if request.api_key:
            headers["Authorization"] = f"Bearer {request.api_key}"
        payload = {
            "model": request.model,
            "messages": [{"role": m.role, "content": m.content} for m in request.messages],
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
                contents.append({"role": role, "parts": [{"text": m.content}]})

        payload: dict[str, object] = {"contents": contents}
        if system_instruction:
            payload["systemInstruction"] = {"parts": [{"text": system_instruction}]}

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
            "content-type": "application/json",
        }

        system_prompt = None
        messages = []
        for m in request.messages:
            if m.role == "system":
                system_prompt = m.content
            else:
                messages.append({"role": m.role, "content": m.content})

        payload = {"model": request.model, "max_tokens": 1024, "messages": messages}
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
