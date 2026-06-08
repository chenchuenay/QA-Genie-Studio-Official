from dataclasses import dataclass
from typing import List, Optional, Dict, Any

@dataclass
class Case:
    id: str
    summary: str
    priority: str
    source: str  # "ai" or "fallback"

@dataclass
class AIDebugInfo:
    status_code: int
    latency_ms: int
    model: str
    error_code: Optional[str]
    error_message: Optional[str]
    raw_response: Optional[Dict] = None

@dataclass
class PipelineResult:
    ai_returned: int
    ai_accepted: int
    ai_rejected: int
    fallback_generated: int
    finalized_cases: List[Case]
    ai_debug: AIDebugInfo
    cloud_function_latency_ms: int
