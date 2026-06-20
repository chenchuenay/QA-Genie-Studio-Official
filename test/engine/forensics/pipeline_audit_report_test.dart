import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';

void main() {
  group('PipelineAuditReport', () {
    test('toJson includes all fields', () {
      final report = PipelineAuditReport(
        traceId: 'TRACE-001',
        rejectedCases: [
          RejectedCaseInfo(title: 'T1', reason: 'Bad', stage: 'S'),
        ],
        repairLog: ['Repair log'],
        diversityBalance: {'security': 2},
        averageConfidence: 0.85,
        fallbackTriggers: ['Fallback'],
        totalInputCases: 10,
        finalizedCases: 5,
        repairedCases: 2,
        rejectedCount: 5,
        missingIntentIds: ['intent-1'],
        prompt: 'Test prompt',
        rawAiResponse: 'Test response',
        aiLatencyMs: 500,
        aiStatusCode: 200,
        aiReturnedCount: 10,
        aiAcceptedCount: 5,
        structuralRejectedCount: 1,
        semanticRejectedCount: 2,
        realismRejectedCount: 1,
        exportSafetyRejectedCount: 1,
        fallbackCount: 1,
        cloudRequestId: 'req-1',
        cloudFunctionVersion: 'v1',
        cloudLatencyMs: 100,
        aiPromptTokens: 50,
        aiCompletionTokens: 100,
        aiTotalTokens: 150,
        aiErrorCode: 'ERR-001',
        aiErrorMessage: 'Something failed',
        aiModelName: 'gpt-4',
        aiApiUrl: 'https://api.openai.com',
        aiHttpStatusCode: 200,
        aiErrorDetails: {'detail': 'value'},
        cloudFunctionName: 'generate',
        cloudFunctionRegion: 'us-east1',
        networkErrorType: 'timeout',
        totalRetriesAttempted: 2,
        wasResponseMalformed: false,
        parserErrorMessages: ['Error 1'],
      );

      final json = report.toJson();
      expect(json['traceId'], 'TRACE-001');
      expect(json['rejectedCases'], hasLength(1));
      expect(json['rejectedCases'].first['title'], 'T1');
      expect(json['repairLog'], ['Repair log']);
      expect(json['diversityBalance'], {'security': 2});
      expect(json['averageConfidence'], 0.85);
      expect(json['fallbackTriggers'], ['Fallback']);
      expect(json['totalInputCases'], 10);
      expect(json['finalizedCases'], 5);
      expect(json['repairedCases'], 2);
      expect(json['rejectedCount'], 5);
      expect(json['missingIntentIds'], ['intent-1']);
      expect(json['prompt'], 'Test prompt');
      expect(json['aiLatencyMs'], 500);
      expect(json['aiStatusCode'], 200);
      expect(json['aiModelName'], 'gpt-4');
      expect(json['parserErrorMessages'], ['Error 1']);
    });

    test('toJson truncates long prompt', () {
      final longPrompt = 'x' * 1500;
      final report = PipelineAuditReport(
        traceId: 'T1',
        prompt: longPrompt,
      );
      final json = report.toJson();
      expect(json['prompt'], endsWith('...[truncated]'));
      expect((json['prompt'] as String).length, 1014);
    });

    test('toJson truncates long rawAiResponse', () {
      final longResponse = 'y' * 6000;
      final report = PipelineAuditReport(
        traceId: 'T1',
        rawAiResponse: longResponse,
      );
      final json = report.toJson();
      expect(json['rawAiResponse'], endsWith('...[truncated]'));
    });

    test('toJson handles null values', () {
      final report = PipelineAuditReport(traceId: 'T1');
      final json = report.toJson();
      expect(json['prompt'], isNull);
      expect(json['aiModelName'], isNull);
      expect(json['parserErrorMessages'], []);
      expect(json['missingIntentIds'], isNull);
    });

    test('RejectedCaseInfo toJson works', () {
      final info = RejectedCaseInfo(title: 'Test', reason: 'Reason', stage: 'Stage');
      final json = info.toJson();
      expect(json['title'], 'Test');
      expect(json['reason'], 'Reason');
      expect(json['stage'], 'Stage');
    });
  });
}
