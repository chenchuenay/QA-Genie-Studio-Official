import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/forensics/error_capture_utils.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';

typedef AiCaller =
    Future<String> Function(String prompt, GenerationRequest request);

class AiGenerationStage {
  static AiCaller? _testCaller;
  static void useTestCaller(AiCaller caller) => _testCaller = caller;

  final AiCaller _aiCaller;
  AiGenerationStage() : _aiCaller = _testCaller ?? _callCloudFunction;

  Future<AiStageResult> execute({
    required String prompt,
    required GenerationRequest request,
  }) async {
    final startTime = DateTime.now();
    int? totalRetries = 0;
    Map<String, dynamic>? lastErrorDetails;

    try {
      final response = await _aiCaller(prompt, request);
      final latencyMs = DateTime.now().difference(startTime).inMilliseconds;
      final structured = jsonDecode(response) as Map<String, dynamic>;

      if (structured['success'] != true) {
        final error = structured['error'] as Map<String, dynamic>?;
        debugPrint('❌ AI_STAGE_ERROR: Cloud function success=false');
        debugPrint('   Code: ${error?['code']}');
        debugPrint('   Message: ${error?['message']}');
      } else {
        debugPrint('✅ AI_STAGE_SUCCESS: Cloud function returned data');
      }

      final errorCode = structured['error']?['code'] as String?;
      return AiStageResult(
        rawResponse: structured['success'] == true
            ? jsonEncode(structured['data'])
            : '',
        statusCode: structured['success'] == true
            ? 200
            : (errorCode == 'LIMIT_REACHED'
                ? 403
                : (errorCode == 'RATE_LIMIT' ? 429 : 500)),
        hasTransportError: structured['success'] != true,
        hardErrorCode: errorCode == 'LIMIT_REACHED' ? errorCode : null,
        errorMessage: (structured['success'] != true && structured['error'] != null) ? structured['error']['message'] : null,
        latencyMs: latencyMs,
        structuredResponse: structured,
        errorDetails: structured['success'] == true
            ? null
            : (structured['error'] as Map<String, dynamic>?),
        modelName: structured['metadata']?['model'] as String?,
        apiUrl: 'https://api.deepseek.com/v1/chat/completions',
        totalRetries: totalRetries,
      );
    } catch (e, st) {
      final errorType = ErrorCaptureUtils.extractNetworkErrorType(e);
      final httpStatus = ErrorCaptureUtils.extractHttpStatusCode(e);
      lastErrorDetails = {
        'exceptionType': e.runtimeType.toString(),
        'message': e.toString(),
        'stackTrace': st.toString(),
        'networkErrorType': errorType,
        'httpStatus': httpStatus,
      };
      ErrorCaptureUtils.logError(
        source: 'AiGenerationStage',
        error: e,
        stack: st,
        additionalInfo: 'Request traceId: ${request.traceId}',
      );

      return AiStageResult(
        rawResponse: '',
        statusCode: httpStatus ?? _extractStatusCode(e.toString()),
        hasTransportError: true,
        errorMessage: e.toString(),
        latencyMs: DateTime.now().difference(startTime).inMilliseconds,
        errorDetails: lastErrorDetails,
        modelName: null,
        apiUrl: null,
        totalRetries: totalRetries,
      );
    }
  }

  static Future<String> _callCloudFunction(
    String prompt,
    GenerationRequest request,
  ) async {
    final payload = <String, dynamic>{
      'requestId': request.traceId,
      'prompt': prompt,
      'module': request.module,
      'feature': request.feature,
      'platform': request.platform,
      'notes': request.constraints,
      'isPro': request.generationMode.toLowerCase() == 'pro',
      'deviceId': request.deviceId,
    };
    if (request.adToken != null && request.adToken!.isNotEmpty) {
      payload['rewardToken'] = request.adToken;
    } else if (request.adToken != null) {
      payload['adToken'] = request.adToken;
    }
    final result = await FunctionsService.call(
      functionName: 'generate',
      payload: payload,
    );
    return jsonEncode(result);
  }

  int? _extractStatusCode(String error) {
    if (error.contains('429') || error.contains('Quota')) return 429;
    if (error.contains('503')) return 503;
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
  final Map<String, dynamic>? structuredResponse;
  final Map<String, dynamic>? errorDetails;
  final String? modelName;
  final String? apiUrl;
  final int? totalRetries;
  final String? hardErrorCode;

  const AiStageResult({
    required this.rawResponse,
    required this.statusCode,
    required this.hasTransportError,
    this.errorMessage,
    this.latencyMs,
    this.structuredResponse,
    this.errorDetails,
    this.modelName,
    this.apiUrl,
    this.totalRetries,
    this.hardErrorCode,
  });
}
