import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';

// ============================================================
// Type definition for an AI caller function.
// ============================================================
typedef AiCaller = Future<String> Function(String prompt);

class AiGenerationStage {
  // ------------------------------------------------------------------
  // TEST‑ONLY STATIC SETTER (no effect in production)
  // ------------------------------------------------------------------
  static AiCaller? _testCaller;

  /// Call this before running any test that uses direct Gemini API.
  /// This has no effect in production unless explicitly called.
  static void useTestCaller(AiCaller caller) {
    _testCaller = caller;
  }

  // The actual AI caller used by this instance.
  final AiCaller _aiCaller;

  // ------------------------------------------------------------------
  // Constructor: uses cloud function by default, but if a test caller
  // was set via useTestCaller(), it will be used instead.
  // ------------------------------------------------------------------
  AiGenerationStage() : _aiCaller = _testCaller ?? _callCloudFunction;

  // ------------------------------------------------------------------
  // Execute the generation: measure latency, call AI, return result.
  // ------------------------------------------------------------------
  Future<AiStageResult> execute({required String prompt}) async {
    final startTime = DateTime.now();
    try {
      final response = await _aiCaller(prompt);
      final latencyMs = DateTime.now().difference(startTime).inMilliseconds;
      return AiStageResult(
        rawResponse: response,
        statusCode: 200,
        hasTransportError: false,
        latencyMs: latencyMs,
      );
    } catch (e) {
      final error = e.toString();
      final statusCode = _extractStatusCode(error);
      return AiStageResult(
        rawResponse: '',
        statusCode: statusCode,
        hasTransportError: true,
        errorMessage: error,
      );
    }
  }

  // ------------------------------------------------------------------
  // Default AI caller: Firebase Cloud Function.
  // ------------------------------------------------------------------
  static Future<String> _callCloudFunction(String prompt) async {
    final result = await FunctionsService.call(
      functionName: 'generateTestCases',
      payload: {'prompt': prompt},
    );
    return result.toString();
  }

  // ------------------------------------------------------------------
  // Extract HTTP status code from error string (for fallback logic).
  // ------------------------------------------------------------------
  int? _extractStatusCode(String error) {
    if (error.contains('429') || error.contains('Quota exhausted')) return 429;
    if (error.contains('503') || error.contains('unavailable')) return 503;
    if (error.contains('500')) return 500;
    return null;
  }
}

// ------------------------------------------------------------------
// Result of an AI call, includes latency for logging.
// ------------------------------------------------------------------
class AiStageResult {
  final String rawResponse;
  final int? statusCode;
  final bool hasTransportError;
  final String? errorMessage;
  final int? latencyMs; // NEW: for forensic logging

  const AiStageResult({
    required this.rawResponse,
    required this.statusCode,
    required this.hasTransportError,
    this.errorMessage,
    this.latencyMs,
  });
}
