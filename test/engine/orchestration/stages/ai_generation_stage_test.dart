import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/orchestration/stages/ai_generation_stage.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';

final _noopCaller = (String prompt, GenerationRequest request) async {
  return jsonEncode({'success': false, 'error': {'code': 'UNKNOWN', 'message': 'noop'}});
};

void main() {
  group('AiGenerationStage', () {
    setUp(() {
      AiGenerationStage.useTestCaller(_noopCaller);
    });

    test('execute returns success result when cloud function succeeds', () async {
      AiGenerationStage.useTestCaller((prompt, request) async {
        return jsonEncode({
          'success': true,
          'data': {'testCases': [{'id': 'TC_001', 'title': 'Test'}]},
          'metadata': {'model': 'deepseek-v3'},
        });
      });
      final stage = AiGenerationStage();
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 1,
        traceId: 'trace-1',
      );
      final result = await stage.execute(prompt: 'test prompt', request: request);
      expect(result.hasTransportError, isFalse);
      expect(result.statusCode, equals(200));
      expect(result.rawResponse, isNotEmpty);
      expect(result.modelName, equals('deepseek-v3'));
    });

    test('execute returns error result when cloud function fails', () async {
      AiGenerationStage.useTestCaller((prompt, request) async {
        return jsonEncode({
          'success': false,
          'error': {'code': 'LIMIT_REACHED', 'message': 'Quota exceeded'},
        });
      });
      final stage = AiGenerationStage();
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 1,
        traceId: 'trace-1',
      );
      final result = await stage.execute(prompt: 'test', request: request);
      expect(result.hasTransportError, isTrue);
      expect(result.statusCode, equals(403));
      expect(result.hardErrorCode, equals('LIMIT_REACHED'));
      expect(result.rawResponse, isEmpty);
    });

    test('execute returns 429 for rate limit error', () async {
      AiGenerationStage.useTestCaller((prompt, request) async {
        return jsonEncode({
          'success': false,
          'error': {'code': 'RATE_LIMIT', 'message': 'Too fast'},
        });
      });
      final stage = AiGenerationStage();
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 1,
        traceId: 'trace-1',
      );
      final result = await stage.execute(prompt: 'test', request: request);
      expect(result.statusCode, equals(429));
    });

    test('execute returns generic error for unknown error code', () async {
      AiGenerationStage.useTestCaller((prompt, request) async {
        return jsonEncode({
          'success': false,
          'error': {'code': 'UNKNOWN', 'message': 'Something went wrong'},
        });
      });
      final stage = AiGenerationStage();
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 1,
        traceId: 'trace-1',
      );
      final result = await stage.execute(prompt: 'test', request: request);
      expect(result.statusCode, equals(500));
    });

    test('execute handles exceptions from ai caller', () async {
      AiGenerationStage.useTestCaller((prompt, request) async {
        throw Exception('Network error: SocketException');
      });
      final stage = AiGenerationStage();
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 1,
        traceId: 'trace-1',
      );
      final result = await stage.execute(prompt: 'test', request: request);
      expect(result.hasTransportError, isTrue);
      expect(result.rawResponse, isEmpty);
      expect(result.errorDetails, isNotNull);
    });

    test('execute includes apiUrl in result', () async {
      AiGenerationStage.useTestCaller((prompt, request) async {
        return jsonEncode({'success': true, 'data': []});
      });
      final stage = AiGenerationStage();
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 1,
        traceId: 'trace-1',
      );
      final result = await stage.execute(prompt: 'test', request: request);
      expect(result.apiUrl, contains('deepseek'));
    });

    test('execute includes latency in result', () async {
      AiGenerationStage.useTestCaller((prompt, request) async {
        return jsonEncode({'success': true, 'data': []});
      });
      final stage = AiGenerationStage();
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 1,
        traceId: 'trace-1',
      );
      final result = await stage.execute(prompt: 'test', request: request);
      expect(result.latencyMs, greaterThanOrEqualTo(0));
    });
  });
}
