from typing import List, Dict, Any

class ValidationError(Exception):
    pass

def validate_ai_output(ai_response: Dict[str, Any], expected_count: int):
    """
    Validates the AI response structure and case count.
    Raises ValidationError with INVALID_COUNT or INVALID_SCHEMA.
    """
    if "cases" not in ai_response:
        raise ValidationError(f"INVALID_COUNT: missing 'cases' key")
    
    cases = ai_response.get("cases", [])
    if len(cases) != expected_count:
        raise ValidationError(f"INVALID_COUNT: expected {expected_count}, got {len(cases)}")
    
    # Validate each case has required fields
    for idx, case in enumerate(cases):
        if not all(k in case for k in ("id", "summary", "priority")):
            raise ValidationError(f"INVALID_SCHEMA: case {idx} missing required fields")
        if case["priority"] not in ["High", "Medium", "Low"]:
            raise ValidationError(f"INVALID_SCHEMA: case {idx} has invalid priority '{case['priority']}'")
    
    return True
