import time
import json
import os
from openai import OpenAI
from models import AIDebugInfo
from config import AI_MODEL, MAX_RETRIES

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def call_ai(input_text: str, expected_count: int):
    start_time = time.time()
    system_prompt = f"""
    You are a case extractor. Return exactly {expected_count} case objects in JSON.
    Format: {{"cases": [{{"id": "1", "summary": "...", "priority": "High/Medium/Low"}}]}}
    No extra text.
    """
    user_prompt = f"Input: {input_text}\nExtract {expected_count} cases."
    
    def _call():
        response = client.chat.completions.create(
            model=AI_MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.2,
            response_format={"type": "json_object"}
        )
        return json.loads(response.choices[0].message.content)
    
    try:
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
                time.sleep(2 ** attempt)
    except Exception as e:
        latency = int((time.time() - start_time) * 1000)
        debug = AIDebugInfo(
            status_code=500,
            latency_ms=latency,
            model=AI_MODEL,
            error_code="UNKNOWN",
            error_message=str(e)
        )
        return [], debug
