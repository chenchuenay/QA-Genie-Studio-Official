from models import Case

def generate_fallback_cases(count: int) -> list:
    """Generates mock cases when AI fails validation."""
    cases = []
    for i in range(1, count + 1):
        cases.append(Case(
            id=f"fallback_{i}",
            summary=f"Fallback case {i}: Auto-generated due to AI validation failure.",
            priority="Medium",
            source="fallback"
        ))
    return cases
