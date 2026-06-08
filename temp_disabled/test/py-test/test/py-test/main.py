import os
from dotenv import load_dotenv
load_dotenv()

from models import PipelineResult, Case, AIDebugInfo
from ai_client import call_ai
from validator import validate_ai_output, ValidationError
from fallback import generate_fallback_cases
from cloud_function import finalize_cases
from config import EXPECTED_CASE_COUNT

def run_pipeline(input_text: str) -> PipelineResult:
    print("\n--- Starting Pipeline ---")
    
    # Step 1: Call AI
    ai_cases_raw, ai_debug = call_ai(input_text, EXPECTED_CASE_COUNT)
    ai_returned = len(ai_cases_raw)
    
    # Step 2: Validate
    ai_accepted = 0
    ai_rejected = 0
    fallback_cases = []
    
    # Reconstruct the full response dict for validator
    ai_full_response = {"cases": ai_cases_raw}
    
    try:
        validate_ai_output(ai_full_response, EXPECTED_CASE_COUNT)
        # Validation passed
        ai_accepted = ai_returned
        # Convert raw dicts to Case objects
        cases_to_finalize = [
            Case(
                id=case.get("id", ""),
                summary=case.get("summary", ""),
                priority=case.get("priority", "Medium"),
                source="ai"
            )
            for case in ai_cases_raw
        ]
        print(f"✓ AI output validated: {ai_accepted} cases accepted")
    except ValidationError as e:
        print(f"✗ Validation failed: {e}")
        ai_rejected = ai_returned
        # Trigger fallback
        fallback_cases = generate_fallback_cases(EXPECTED_CASE_COUNT)
        cases_to_finalize = fallback_cases
        print(f"✓ Fallback generated {len(fallback_cases)} cases")
    
    fallback_generated = len(fallback_cases)
    
    # Step 3: Cloud function finalization
    finalized_cases, cloud_latency = finalize_cases(cases_to_finalize)
    
    return PipelineResult(
        ai_returned=ai_returned,
        ai_accepted=ai_accepted,
        ai_rejected=ai_rejected,
        fallback_generated=fallback_generated,
        finalized_cases=finalized_cases,
        ai_debug=ai_debug,
        cloud_function_latency_ms=cloud_latency
    )

def print_summary(result: PipelineResult):
    print("\n" + "="*50)
    print("# PIPELINE SUMMARY")
    print(f"- AI Returned: {result.ai_returned}")
    print(f"- AI Accepted: {result.ai_accepted}")
    print(f"- AI Rejected: {result.ai_rejected}")
    print(f"- Fallback Generated: {result.fallback_generated}")
    print(f"- Finalized Cases: {len(result.finalized_cases)}")
    print("\n# PIPELINE FLOW")
    print(f"- AI → Parsed → Validated → Finalized")
    print(f"  [{result.ai_returned} → {result.ai_accepted} → {len(result.finalized_cases)}]")
    print("\n# AI")
    print(f"- Status Code: {result.ai_debug.status_code}")
    print(f"- Latency (ms): {result.ai_debug.latency_ms}")
    print(f"- Model: {result.ai_debug.model}")
    print(f"- Error Code: {result.ai_debug.error_code or 'N/A'}")
    print(f"- Error Message: {result.ai_debug.error_message or 'N/A'}")
    print("\n# CLOUD FUNCTION")
    print(f"- Request ID: req_1780684957048_j64aa")
    print(f"- Version: v2.0")
    print(f"- Latency (ms): {result.cloud_function_latency_ms}")
    print("="*50)
    
    # Optional: show first few cases
    if result.finalized_cases:
        print("\n--- Sample Finalized Cases ---")
        for case in result.finalized_cases[:3]:
            print(f"ID: {case.id} | Priority: {case.priority} | Source: {case.source}")
            print(f"    {case.summary[:80]}...")

if __name__ == "__main__":
    # Example input text with 5 incidents
    sample_input = """
    Incident reports:
    1. Critical: Server outage in us-east-1 region affecting 10,000 customers.
    2. High: Security breach detected in billing database – potential data leak.
    3. Medium: Database migration failed during off-peak hours, requiring rollback.
    4. Low: Minor UI glitch on Safari browser's login page.
    5. Medium: Overdue invoice of $5,000 from Acme Corp needs collection.
    """
    
    result = run_pipeline(sample_input)
    print_summary(result)
