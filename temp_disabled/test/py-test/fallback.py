from models import Case

def generate_fallback_cases(count: int) -> list:
    cases = []
    for i in range(1, count + 1):
        cases.append(Case(
            id=f"fallback_{i}",
            summary=f"Fallback case {i}: auto-generated due to AI failure",
            priority="Medium",
            source="fallback"
        ))
    return cases
