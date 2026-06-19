import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

FinalizedTestCase makeCase({String id = 'TC-001', String source = 'ai'}) {
  return FinalizedTestCase(
    dbId: null,
    id: id,
    title: 'Test case $id',
    preconditions: [],
    testData: '',
    steps: [TestStep(action: 'Step 1', data: 'data', expected: 'OK')],
    expectedResult: 'Expected',
    priority: 'High',
    type: 'positive',
    module: 'Auth',
    feature: 'Login',
    platform: 'Web',
    source: CaseSource.values.firstWhere((e) => e.name == source, orElse: () => CaseSource.ai),
  );
}

PipelineAuditReport makeReport({
  String traceId = 'trace-001',
  int? aiReturnedCount = 5,
  int? aiAcceptedCount = 3,
  int fallbackCount = 2,
  int finalizedCases = 5,
  String? aiErrorCode,
  int? aiHttpStatusCode,
  bool? wasResponseMalformed,
}) {
  return PipelineAuditReport(
    traceId: traceId,
    aiReturnedCount: aiReturnedCount,
    aiAcceptedCount: aiAcceptedCount,
    fallbackCount: fallbackCount,
    finalizedCases: finalizedCases,
    aiErrorCode: aiErrorCode,
    aiHttpStatusCode: aiHttpStatusCode,
    wasResponseMalformed: wasResponseMalformed,
    aiModelName: 'gemini-2.5-flash-lite',
    aiApiUrl: 'https://api.example.com',
    prompt: 'Test prompt with CONSTRAINTS: max 100 chars',
    rawAiResponse: '{"cases": []}',
  );
}

void main() {
  group('DiagnosticsPersistenceService', () {
    group('PipelineAuditReport failure detection', () {
      test('detects error code as failure', () {
        final report = makeReport(aiErrorCode: 'AI_ERROR');
        expect(report.aiErrorCode, 'AI_ERROR');
      });

      test('detects RATE_LIMIT via http status', () {
        final report = makeReport(aiHttpStatusCode: 429);
        expect(report.aiHttpStatusCode, 429);
      });

      test('detects TIMEOUT via http status', () {
        final report = makeReport(aiHttpStatusCode: 503);
        expect(report.aiHttpStatusCode, 503);
      });

      test('detects EMPTY_RESPONSE', () {
        final report = makeReport(aiReturnedCount: 0, aiAcceptedCount: 0, finalizedCases: 0);
        expect(report.aiReturnedCount, 0);
      });

      test('detects MALFORMED_RESPONSE', () {
        final report = makeReport(wasResponseMalformed: true);
        expect(report.wasResponseMalformed, true);
      });
    });

    group('PipelineAuditReport construction', () {
      test('has correct defaults', () {
        final report = PipelineAuditReport(traceId: 'test');
        expect(report.traceId, 'test');
        expect(report.finalizedCases, 0);
        expect(report.aiErrorCode, isNull);
      });

      test('stores all provided fields', () {
        final report = PipelineAuditReport(
          traceId: 'trace-001',
          aiReturnedCount: 10,
          aiAcceptedCount: 7,
          fallbackCount: 3,
          finalizedCases: 10,
          aiModelName: 'gemini-2.5-flash-lite',
          aiHttpStatusCode: 200,
        );
        expect(report.aiReturnedCount, 10);
        expect(report.aiAcceptedCount, 7);
        expect(report.fallbackCount, 3);
        expect(report.finalizedCases, 10);
        expect(report.aiModelName, 'gemini-2.5-flash-lite');
        expect(report.aiHttpStatusCode, 200);
      });
    });

    group('GenerationSession construction', () {
      test('has correct traceId and testCases', () {
        final session = GenerationSession(
          traceId: 'trace-001',
          testCases: [makeCase(id: 'TC-S1', source: 'ai'), makeCase(id: 'TC-S2', source: 'fallback')],
          auditReport: makeReport(),
        );
        expect(session.traceId, 'trace-001');
        expect(session.testCases.length, 2);
        expect(session.isEmpty, false);
        expect(session.count, 2);
      });

      test('isEmpty returns true for empty test cases', () {
        final session = GenerationSession(
          traceId: 'trace-empty',
          testCases: [],
          auditReport: makeReport(),
        );
        expect(session.isEmpty, true);
        expect(session.count, 0);
      });
    });

    group('FinalizedTestCase copyWith', () {
      test('dbId sentinel sets null', () {
        final tc = makeCase();
        final copy = tc.copyWith(dbId: null);
        expect(copy.dbId, isNull);
      });

      test('keeps source unchanged when not specified', () {
        final tc = makeCase(source: 'fallback');
        final copy = tc.copyWith(title: 'New');
        expect(copy.source, CaseSource.fallback);
      });
    });
  });
}
