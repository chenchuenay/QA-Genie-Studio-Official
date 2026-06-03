import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/forensics/pipeline_observer.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';

typedef AiCaller =
    Future<String> Function(String prompt, GenerationRequest request);

class AiGenerationStage {
  static AiCaller? _testCaller;

  static void useTestCaller(AiCaller caller) {
    _testCaller = caller;
  }

  final AiCaller _aiCaller;

  AiGenerationStage() : _aiCaller = _testCaller ?? _callCloudFunction;

  Future<AiStageResult> execute({
    required String prompt,
    required GenerationRequest request,
  }) async {
    debugPrint('REACHED_AIGENERATION_STAGE');
    final startTime = DateTime.now();
    try {
      final response = await _aiCaller(prompt, request);
      final latencyMs = DateTime.now().difference(startTime).inMilliseconds;

      try {
        final decoded = jsonDecode(response);
        final candidates = decoded['candidates'] as List? ?? [];
        final parts = candidates.isNotEmpty
            ? (candidates[0]['content']['parts'] as List? ?? [])
            : [];
        final finishReason = candidates.isNotEmpty
            ? candidates[0]['finishReason']
            : 'unknown';
        final safetyBlocks = candidates.isNotEmpty
            ? (candidates[0]['safetyRatings'] as List? ?? [])
            : [];

        PipelineForensics.instance.onTraceEvent(
          '\n[AI PAYLOAD]\ncandidateCount=${candidates.length}',
        );
        PipelineForensics.instance.onTraceEvent('partCount=${parts.length}');
        PipelineForensics.instance.onTraceEvent('finishReason=$finishReason');
        PipelineForensics.instance.onTraceEvent(
          'safetyBlocks=${safetyBlocks.length}',
        );
      } catch (e) {
        PipelineForensics.instance.onTraceEvent(
          '\n[AI PAYLOAD]\nerror=Failed to parse for Section 4: $e',
        );
      }

      return AiStageResult(
        rawResponse: response,
        statusCode: 200,
        hasTransportError: false,
        latencyMs: latencyMs,
      );
    } catch (e, st) {
      debugPrint('==============================');
      debugPrint('AI_STAGE_EXCEPTION=$e');
      debugPrint('AI_STAGE_STACK=$st');
      debugPrint('==============================');

      final error = e.toString();

      PipelineForensics.instance.onTraceEvent(
        '\n[AI STAGE ERROR]\nerror=$error',
      );

      final statusCode = _extractStatusCode(error);

      return AiStageResult(
        rawResponse: '',
        statusCode: statusCode,
        hasTransportError: true,
        errorMessage: error,
      );
    }
  }

  static Future<String> _callCloudFunction(
    String prompt,
    GenerationRequest request,
  ) async {
    debugPrint('CF_MODULE=${request.module}');
    debugPrint('CF_FEATURE=${request.feature}');
    debugPrint('CF_PLATFORM=${request.platform}');
    debugPrint('CF_MODE=${request.generationMode}');
    debugPrint('CF_NOTES=${request.constraints}');

    final result = await FunctionsService.call(
      functionName: 'generate',
      payload: {
        'prompt': prompt,
        'module': request.module,
        'feature': request.feature,
        'platform': request.platform,
        'notes': request.constraints,
        'isPro': request.generationMode.toLowerCase() == 'pro',
      },
    );

    // LOGS
    debugPrint('--- AI TRANSPORT DIAGNOSTIC ---');
    debugPrint('LOG_A: result runtimeType=${result.runtimeType}');
    debugPrint('LOG_B: result.keys=${result.keys}');
    debugPrint('LOG_C: result raw payload=$result');

    final stringResult = jsonEncode(result);
    debugPrint('LOG_D: returned string length=${stringResult.length}');
    debugPrint('---------------------------------');

    return jsonEncode(result);
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
