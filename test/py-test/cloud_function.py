import time

def finalize_cases(cases: list) -> tuple:
    # Simulate cloud function latency
    time.sleep(0.0025)
    latency_ms = 2501  # fixed for demo
    return cases, latency_ms
