import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';

void main() {
  group('CaseMetadata', () {
    test('can be created with default values', () {
      final meta = CaseMetadata(source: CaseSource.ai, traceId: 'trace-1');
      expect(meta.source, CaseSource.ai);
      expect(meta.traceId, 'trace-1');
      expect(meta.repairHistory, isEmpty);
      expect(meta.validationIssues, isEmpty);
      expect(meta.qualityPenalties, isEmpty);
      expect(meta.semanticProfile, 'unknown');
      expect(meta.diversitySignals, isEmpty);
      expect(meta.fingerprint, isNull);
      expect(meta.confidenceScore, 1.0);
      expect(meta.intentId, '__unknown__');
    });

    test('origin returns source.name', () {
      final meta = CaseMetadata(source: CaseSource.fallback, traceId: 't1');
      expect(meta.origin, 'fallback');
    });

    test('copy creates independent copy', () {
      final meta = CaseMetadata(
        source: CaseSource.ai,
        traceId: 't1',
        repairHistory: ['repair1'],
        validationIssues: ['issue1'],
        qualityPenalties: {'penalty': 0.5},
        semanticProfile: 'known',
        diversitySignals: {'signal1'},
        fingerprint: 'fp1',
        confidenceScore: 0.8,
        intentId: 'intent-1',
      );
      final copy = meta.copy();
      expect(copy.source, meta.source);
      expect(copy.traceId, meta.traceId);
      expect(copy.repairHistory, meta.repairHistory);
      expect(copy.validationIssues, meta.validationIssues);
      expect(copy.qualityPenalties, meta.qualityPenalties);
      expect(copy.semanticProfile, meta.semanticProfile);
      expect(copy.diversitySignals, meta.diversitySignals);
      expect(copy.fingerprint, meta.fingerprint);
      expect(copy.confidenceScore, meta.confidenceScore);
      expect(copy.intentId, meta.intentId);
      copy.repairHistory.add('repair2');
      expect(meta.repairHistory.length, 1);
    });
  });

  group('WorkingCase', () {
    FinalizedTestCase _makeFinalized() {
      return FinalizedTestCase(
        id: 'tc-1',
        title: 'Test login',
        preconditions: ['User is registered'],
        testData: 'user@example.com',
        steps: [TestStep(action: 'Enter email', data: 'user@example.com', expected: 'Field filled')],
        expectedResult: 'Login successful',
        priority: 'High',
        type: 'Positive',
        module: 'Auth',
        feature: 'Login',
        platform: 'Mobile',
      );
    }

    test('can be created with all fields', () {
      final meta = CaseMetadata(source: CaseSource.ai, traceId: 't1');
      final wc = WorkingCase(
        id: 'wc-1',
        title: 'Test login',
        module: 'Auth',
        feature: 'Login',
        platform: 'Mobile',
        priority: 'High',
        type: 'Positive',
        categoryLock: 'positive',
        preconditions: ['User is registered'],
        testData: 'user@example.com',
        steps: [TestStep(action: 'Enter email', data: 'user@example.com', expected: 'Field filled')],
        expectedResult: 'Login successful',
        actualResult: '',
        status: 'Not Executed',
        metadata: meta,
        intentId: 'intent-1',
      );
      expect(wc.id, 'wc-1');
      expect(wc.title, 'Test login');
      expect(wc.module, 'Auth');
      expect(wc.feature, 'Login');
      expect(wc.platform, 'Mobile');
      expect(wc.priority, 'High');
      expect(wc.type, 'Positive');
      expect(wc.categoryLock, 'positive');
      expect(wc.preconditions, ['User is registered']);
      expect(wc.testData, 'user@example.com');
      expect(wc.steps.length, 1);
      expect(wc.expectedResult, 'Login successful');
      expect(wc.actualResult, '');
      expect(wc.status, 'Not Executed');
      expect(wc.metadata.source, CaseSource.ai);
      expect(wc.intentId, 'intent-1');
      expect(wc.isNegative, isFalse);
      expect(wc.hasConstraints, isFalse);
    });

    test('isNegative returns true for negative type', () {
      final meta = CaseMetadata(source: CaseSource.ai, traceId: 't1');
      final wc = WorkingCase(
        id: '1',
        title: 'Test',
        module: 'M',
        feature: 'F',
        platform: 'P',
        priority: 'High',
        type: 'Negative',
        categoryLock: 'negative',
        preconditions: [],
        testData: '',
        steps: [],
        expectedResult: '',
        actualResult: '',
        status: '',
        metadata: meta,
      );
      expect(wc.isNegative, isTrue);
    });

    test('hasConstraints returns true when constraints is non-empty', () {
      final meta = CaseMetadata(source: CaseSource.ai, traceId: 't1');
      final wc = WorkingCase(
        id: '1',
        title: 'Test',
        module: 'M',
        feature: 'F',
        platform: 'P',
        priority: 'High',
        type: 'Positive',
        categoryLock: 'positive',
        constraints: 'security',
        preconditions: [],
        testData: '',
        steps: [],
        expectedResult: '',
        actualResult: '',
        status: '',
        metadata: meta,
      );
      expect(wc.hasConstraints, isTrue);
    });

    test('hasConstraints returns false for null constraints', () {
      final meta = CaseMetadata(source: CaseSource.ai, traceId: 't1');
      final wc = WorkingCase(
        id: '1',
        title: 'Test',
        module: 'M',
        feature: 'F',
        platform: 'P',
        priority: 'High',
        type: 'Positive',
        categoryLock: 'positive',
        preconditions: [],
        testData: '',
        steps: [],
        expectedResult: '',
        actualResult: '',
        status: '',
        metadata: meta,
      );
      expect(wc.hasConstraints, isFalse);
    });

    test('copy creates independent copy', () {
      final ft = _makeFinalized();
      final meta = CaseMetadata(
        source: CaseSource.ai,
        traceId: 't1',
        repairHistory: ['r1'],
      );
      final wc = WorkingCase(
        id: ft.id,
        title: ft.title,
        module: ft.module,
        feature: ft.feature,
        platform: ft.platform,
        priority: ft.priority,
        type: ft.type,
        categoryLock: 'positive',
        preconditions: ft.preconditions,
        testData: ft.testData,
        steps: ft.steps,
        expectedResult: ft.expectedResult,
        actualResult: ft.actualResult,
        status: ft.status,
        metadata: meta,
        intentId: 'intent-1',
      );
      final copy = wc.copy();
      expect(copy.id, wc.id);
      expect(copy.title, wc.title);
      expect(copy.steps.length, wc.steps.length);
      copy.steps.add(TestStep(action: 'new', data: '', expected: ''));
      expect(wc.steps.length, 1);
      copy.metadata.repairHistory.add('r2');
      expect(wc.metadata.repairHistory.length, 1);
    });

    test('fromJson parses correctly', () {
      final json = {
        'id': 'json-1',
        'title': 'JSON test',
        'module': 'Auth',
        'feature': 'Login',
        'platform': 'Web',
        'priority': 'Low',
        'type': 'Negative',
        'categoryLock': 'negative',
        'constraints': 'session only',
        'preconditions': ['Logged in'],
        'testData': 'data',
        'steps': [
          {'action': 'Click', 'data': 'Button', 'expected': 'Success'},
        ],
        'expectedResult': 'Done',
        'actualResult': 'N/A',
        'status': 'Passed',
        'intent_id': 'intent-json',
      };
      final wc = WorkingCase.fromJson(json, traceId: 'trace-json');
      expect(wc.id, 'json-1');
      expect(wc.title, 'JSON test');
      expect(wc.module, 'Auth');
      expect(wc.feature, 'Login');
      expect(wc.platform, 'Web');
      expect(wc.priority, 'Low');
      expect(wc.type, 'Negative');
      expect(wc.categoryLock, 'negative');
      expect(wc.constraints, 'session only');
      expect(wc.preconditions, ['Logged in']);
      expect(wc.testData, 'data');
      expect(wc.steps.length, 1);
      expect(wc.steps[0].action, 'Click');
      expect(wc.expectedResult, 'Done');
      expect(wc.actualResult, 'N/A');
      expect(wc.status, 'Passed');
      expect(wc.metadata.traceId, 'trace-json');
      expect(wc.intentId, 'intent-json');
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{};
      final wc = WorkingCase.fromJson(json);
      expect(wc.id, '');
      expect(wc.title, '');
      expect(wc.module, '');
      expect(wc.feature, '');
      expect(wc.platform, '');
      expect(wc.priority, 'Medium');
      expect(wc.type, 'Positive');
      expect(wc.categoryLock, 'positive');
      expect(wc.constraints, isNull);
      expect(wc.preconditions, isEmpty);
      expect(wc.testData, '');
      expect(wc.steps, isEmpty);
      expect(wc.expectedResult, '');
      expect(wc.actualResult, '');
      expect(wc.status, 'Not Executed');
      expect(wc.intentId, '__unknown__');
    });

    test('toJson produces correct map', () {
      final meta = CaseMetadata(source: CaseSource.ai, traceId: 't1');
      final wc = WorkingCase(
        id: 'wc-1',
        title: 'Test',
        module: 'M',
        feature: 'F',
        platform: 'P',
        priority: 'High',
        type: 'Positive',
        categoryLock: 'positive',
        constraints: 'security',
        preconditions: ['Pre'],
        testData: 'Data',
        steps: [TestStep(action: 'Action', data: 'Data', expected: 'Exp')],
        expectedResult: 'Result',
        actualResult: 'Actual',
        status: 'Passed',
        metadata: meta,
        intentId: 'i1',
      );
      final json = wc.toJson();
      expect(json['id'], 'wc-1');
      expect(json['title'], 'Test');
      expect(json['module'], 'M');
      expect(json['feature'], 'F');
      expect(json['platform'], 'P');
      expect(json['priority'], 'High');
      expect(json['type'], 'Positive');
      expect(json['categoryLock'], 'positive');
      expect(json['constraints'], 'security');
      expect(json['preconditions'], ['Pre']);
      expect(json['testData'], 'Data');
      expect((json['steps'] as List).length, 1);
      expect(json['expectedResult'], 'Result');
      expect(json['actualResult'], 'Actual');
      expect(json['status'], 'Passed');
      expect(json['intent_id'], 'i1');
    });
  });

  group('QuotaExceededException', () {
    test('can be created with message', () {
      final ex = QuotaExceededException('Out of quota');
      expect(ex.message, 'Out of quota');
      expect(ex.isRateLimit, isFalse);
      expect(ex.resetTimeMillis, isNull);
    });

    test('can be created with rate limit and reset time', () {
      final ex = QuotaExceededException('Rate limited', isRateLimit: true, resetTimeMillis: 1000);
      expect(ex.isRateLimit, isTrue);
      expect(ex.resetTimeMillis, 1000);
    });

    test('toString returns message', () {
      final ex = QuotaExceededException('Out of quota');
      expect(ex.toString(), 'QuotaExceededException: Out of quota');
    });
  });

  group('GenerationSession', () {
    test('can be created with traceId, testCases, auditReport', () {
      final report = PipelineAuditReport(traceId: 't1');
      final session = GenerationSession(
        traceId: 't1',
        testCases: [],
        auditReport: report,
      );
      expect(session.traceId, 't1');
      expect(session.testCases, isEmpty);
      expect(session.auditReport, report);
      expect(session.isEmpty, isTrue);
      expect(session.count, 0);
      expect(session.createdAt, greaterThan(0));
    });

    test('isEmpty returns false when testCases is not empty', () {
      final report = PipelineAuditReport(traceId: 't1');
      final tc = FinalizedTestCase(
        id: '1',
        title: 'Test',
        preconditions: [],
        testData: '',
        steps: [],
        expectedResult: '',
        priority: 'High',
        type: 'Positive',
        module: 'M',
        feature: 'F',
        platform: 'P',
      );
      final session = GenerationSession(
        traceId: 't1',
        testCases: [tc],
        auditReport: report,
      );
      expect(session.isEmpty, isFalse);
      expect(session.count, 1);
    });
  });

  group('RejectedCaseInfo', () {
    test('can be created with title, reason, stage', () {
      final info = RejectedCaseInfo(
        title: 'Test case',
        reason: 'Duplicate',
        stage: 'validation',
      );
      expect(info.title, 'Test case');
      expect(info.reason, 'Duplicate');
      expect(info.stage, 'validation');
    });

    test('toJson returns correct map', () {
      final info = RejectedCaseInfo(title: 'T', reason: 'R', stage: 'S');
      final json = info.toJson();
      expect(json['title'], 'T');
      expect(json['reason'], 'R');
      expect(json['stage'], 'S');
    });
  });

  group('GenerationRequest', () {
    test('can be created with required fields', () {
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'Mobile',
        generationMode: 'positive',
        requestedCaseCount: 5,
        traceId: 'trace-1',
      );
      expect(request.module, 'Auth');
      expect(request.feature, 'Login');
      expect(request.platform, 'Mobile');
      expect(request.generationMode, 'positive');
      expect(request.requestedCaseCount, 5);
      expect(request.traceId, 'trace-1');
      expect(request.constraints, '');
      expect(request.domain, 'general');
      expect(request.plan, isEmpty);
      expect(request.adToken, isNull);
      expect(request.deviceId, isNull);
    });

    test('can be created with all optional fields', () {
      final request = GenerationRequest(
        module: 'M',
        feature: 'F',
        platform: 'P',
        generationMode: 'negative',
        requestedCaseCount: 3,
        constraints: 'security',
        domain: 'identity',
        plan: [{'key': 'value'}],
        traceId: 't1',
        adToken: 'token123',
        deviceId: 'device456',
      );
      expect(request.constraints, 'security');
      expect(request.domain, 'identity');
      expect(request.plan, [{'key': 'value'}]);
      expect(request.adToken, 'token123');
      expect(request.deviceId, 'device456');
    });
  });

  group('PipelineAuditReport', () {
    test('can be created with traceId only', () {
      final report = PipelineAuditReport(traceId: 'trace-1');
      expect(report.traceId, 'trace-1');
      expect(report.rejectedCases, isEmpty);
      expect(report.repairLog, isEmpty);
      expect(report.diversityBalance, isEmpty);
      expect(report.averageConfidence, 0.0);
      expect(report.fallbackTriggers, isEmpty);
      expect(report.totalInputCases, 0);
      expect(report.finalizedCases, 0);
      expect(report.repairedCases, 0);
      expect(report.rejectedCount, 0);
      expect(report.missingIntentIds, isNull);
      expect(report.hasFailures, isFalse);
    });

    test('hasFailures returns true when rejectedCases is not empty', () {
      final report = PipelineAuditReport(
        traceId: 't1',
        rejectedCases: [RejectedCaseInfo(title: 'T', reason: 'R', stage: 'S')],
      );
      expect(report.hasFailures, isTrue);
    });

    test('toJson returns correct map', () {
      final report = PipelineAuditReport(
        traceId: 't1',
        rejectedCases: [RejectedCaseInfo(title: 'T', reason: 'R', stage: 'S')],
        repairLog: ['repaired'],
        diversityBalance: {'positive': 3},
        averageConfidence: 0.95,
        fallbackTriggers: ['empty'],
        totalInputCases: 10,
        finalizedCases: 8,
        repairedCases: 2,
        rejectedCount: 1,
        missingIntentIds: ['i1'],
        prompt: 'Generate test cases',
        rawAiResponse: 'Some long response that should be truncated...' * 100,
        aiLatencyMs: 1500,
        aiModel: 'gpt-4',
        aiEndpoint: '/v1/completions',
        aiStatusCode: 200,
        aiReturnedCount: 10,
        aiAcceptedCount: 8,
        structuralRejectedCount: 1,
        semanticRejectedCount: 1,
        realismRejectedCount: 0,
        exportSafetyRejectedCount: 0,
        repairedCount: 2,
        fallbackCount: 1,
        cloudRequestId: 'req-1',
        cloudFunctionVersion: 'v1',
        cloudLatencyMs: 200,
        aiPromptTokens: 100,
        aiCompletionTokens: 200,
        aiTotalTokens: 300,
        aiErrorCode: null,
        aiErrorMessage: null,
        aiModelName: 'gpt-4',
        aiApiUrl: 'https://api.openai.com',
        aiHttpStatusCode: 200,
        aiErrorDetails: null,
        cloudFunctionName: 'generate',
        cloudFunctionRegion: 'us-central1',
        networkErrorType: null,
        totalRetriesAttempted: 0,
        wasResponseMalformed: false,
        parserErrorMessages: ['error1'],
      );
      final json = report.toJson();
      expect(json['traceId'], 't1');
      expect((json['rejectedCases'] as List).length, 1);
      expect((json['repairLog'] as List).length, 1);
      expect(json['averageConfidence'], 0.95);
      expect(json['totalInputCases'], 10);
      expect(json['finalizedCases'], 8);
      expect(json['repairedCases'], 2);
      expect(json['rejectedCount'], 1);
      expect(json['aiModel'], 'gpt-4');
      expect(json['aiTotalTokens'], 300);
      expect(json['parserErrorMessages'], ['error1']);
    });

    test('toJson truncates prompt and rawAiResponse', () {
      final longPrompt = 'x' * 2000;
      final longResponse = 'y' * 10000;
      final report = PipelineAuditReport(
        traceId: 't1',
        prompt: longPrompt,
        rawAiResponse: longResponse,
      );
      final json = report.toJson();
      expect((json['prompt'] as String).length, 1014);
      expect((json['rawAiResponse'] as String).endsWith('...[truncated]'), isTrue);
    });
  });
}
