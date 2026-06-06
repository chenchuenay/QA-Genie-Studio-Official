import time
import json
import os
from openai import OpenAI
from models import AIDebugInfo
from config import AI_MODEL, MAX_RETRIES

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not GROQ_API_KEY:
    raise ValueError("GROQ_API_KEY not set in .env file")

# Initialize Groq client (OpenAI-compatible)
client = OpenAI(
    api_key=GROQ_API_KEY,
    base_url="https://api.groq.com/openai/v1"
)

def call_ai(input_text: str, expected_count: int):
    """
    Calls Groq's Llama 3.1 8B Instant model to extract cases.
    Returns (cases_list, debug_info)
    """
    start_time = time.time()
    
    # System prompt – instructs the model exactly what to return
    system_prompt = f"""
    You are a case extraction system. Return exactly {expected_count} case objects in strict JSON format.
    
    The JSON must have a single key "cases" containing an array of objects.
    Each object must have exactly these fields:
    - "id": a simple integer as a string (e.g., "1")
    - "summary": a brief one-sentence description of the case
    - "priority": one of "High", "Medium", or "Low"
    
    Do NOT include any extra text, explanations, or markdown. Output ONLY valid JSON.
    
    Example output:
    {{"cases": [
        {{"id": "1", "summary": "Server outage in us-east-1", "priority": "High"}},
        {{"id": "2", "summary": "UI glitch on login", "priority": "Low"}}
    ]}}
    """
    
    user_prompt = f"""
    Extract {expected_count} distinct case summaries from the following text.
    Return exactly {expected_count} cases in the required JSON format.
    
    Text:
    {input_text}
    """
    
    def _call():
        response = client.chat.completions.create(
            model=AI_MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.2,
            # Groq supports response_format for some models (Llama 3.1 8B works well)
            response_format={"type": "json_object"}
        )
        content = response.choices[0].message.content
        return json.loads(content)
    
    # Retry logic with exponential backoff
    for attempt in range(MAX_RETRIES):
        try:
            result = _call()
            latency = int((time.time() - start_time) * 1000)
            debug = AIDebugInfo(
                status_code=200,
                latency_ms=latency,
                model=AI_MODEL,
                error_code=None,
                error_message=None,
                raw_response=result
            )
            cases = result.get("cases", [])
            return cases, debug
        except Exception as e:
            if attempt == MAX_RETRIES - 1:
                latency = int((time.time() - start_time) * 1000)
                debug = AIDebugInfo(
                    status_code=500,
                    latency_ms=latency,
                    model=AI_MODEL,
                    error_code="API_ERROR",
                    error_message=str(e)
                )
                return [], debug
            time.sleep(2 ** attempt)  # exponential backoff: 1, 2, 4 seconds
    
    # Fallback (should never reach here)
    return [], AIDebugInfo(
        status_code=500,
        latency_ms=int((time.time() - start_time) * 1000),
        model=AI_MODEL,
        error_code="UNKNOWN",
        error_message="Max retries exceeded"
    )
