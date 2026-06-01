import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';

typedef AiCaller = Future<String> Function(String prompt);

class AiGenerationStage {
  static AiCaller? _testCaller;

  static void useTestCaller(AiCaller caller) {
    _testCaller = caller;
  }

  final AiCaller _aiCaller;

  AiGenerationStage() : _aiCaller = _testCaller ?? _callCloudFunction;

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

  static Future<String> _callCloudFunction(String prompt) async {
    final result = await FunctionsService.call(
      functionName: 'generateTestCases',
      payload: {'prompt': prompt},
    );
    return result.toString();
  }

  int? _extractStatusCode(String error) {
    if (error.contains('429') || error.contains('Quota exhausted')) return 429;
    if (error.contains('503') || error.contains('unavailable')) return 503;
    if (error.contains('500')) return 500;
    return null;
  }
}

class AiStageResult {
  final String rawResponse;
  final int? statusCode;
  final bool hasTransportError;
  final String? errorMessage;
  final int? latencyMs;

  const AiStageResult({
    required this.rawResponse,
    required this.statusCode,
    required this.hasTransportError,
    this.errorMessage,
    this.latencyMs,
  });
}