from typing import List, Dict, Any

class ValidationError(Exception):
    pass

def validate_ai_output(ai_response: Dict[str, Any], expected_count: int):
    if "cases" not in ai_response:
        raise ValidationError(f"INVALID_COUNT: missing 'cases' key")
    cases = ai_response.get("cases", [])
    if len(cases) != expected_count:
        raise ValidationError(f"INVALID_COUNT: expected {expected_count}, got {len(cases)}")
    # Additional schema validation
    for case in cases:
        if not all(k in case for k in ("id", "summary", "priority")):
            raise ValidationError("INVALID_SCHEMA: missing required fields")
    return True
