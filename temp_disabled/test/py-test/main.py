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
    # Step 1: AI call
    ai_cases, ai_debug = call_ai(input_text, EXPECTED_CASE_COUNT)
    ai_returned = len(ai_cases)
    
    # Step 2: Validate
    ai_accepted = 0
    ai_rejected = 0
    fallback_cases = []
    
    try:
        # Need to reconstruct full response for validator
        ai_full_response = {"cases": [c.__dict__ if hasattr(c, '__dict__') else c for c in ai_cases]}
        validate_ai_output(ai_full_response, EXPECTED_CASE_COUNT)
        ai_accepted = ai_returned
        cases_to_finalize = [Case(id=c.get("id", ""), summary=c.get("summary", ""), priority=c.get("priority", ""), source="ai") for c in ai_cases]
    except ValidationError as e:
        print(f"Validation failed: {e}")
        ai_rejected = ai_returned
        fallback_cases = generate_fallback_cases(EXPECTED_CASE_COUNT)
        cases_to_finalize = fallback_cases
    
    fallback_generated = len(fallback_cases)
    
    # Step 3: Cloud finalize
    finalized, cloud_latency = finalize_cases(cases_to_finalize)
    
    return PipelineResult(
        ai_returned=ai_returned,
        ai_accepted=ai_accepted,
        ai_rejected=ai_rejected,
        fallback_generated=fallback_generated,
        finalized_cases=finalized,
        ai_debug=ai_debug,
        cloud_function_latency_ms=cloud_latency
    )

def print_summary(result: PipelineResult):
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

if __name__ == "__main__":
    sample_input = """
    Incident 1: Server outage in us-east-1.
    Incident 2: Security breach in billing.
    Incident 3: Database migration failure.
    Incident 4: UI glitch on Safari login.
    Incident 5: Overdue invoice from Acme Corp.
    """
    result = run_pipeline(sample_input)
    print_summary(result)
