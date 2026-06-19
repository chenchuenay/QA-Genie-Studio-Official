import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/forensics/pipeline_audit_logger.dart';
import 'package:qa_genie/engine/forensics/models/pipeline_event.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

WorkingCase _makeCase({
  String title = 'Test Case',
  String semanticProfile = 'functional',
  double confidence = 1.0,
  String intentId = '__unknown__',
}) {
  return WorkingCase(
    id: 'TC-001',
    title: title,
    module: 'Auth',
    feature: 'Login',
    platform: 'Android',
    priority: 'High',
    type: 'Functional',
    categoryLock: 'positive',
    preconditions: [],
    testData: '',
    steps: [TestStep(action: 'Click', expected: 'Opens')],
    expectedResult: 'Should pass',
    actualResult: '',
    status: 'Not Executed',
    metadata: CaseMetadata(
      source: CaseSource.ai,
      traceId: 'trace-1',
      semanticProfile: semanticProfile,
      confidenceScore: confidence,
      intentId: intentId,
    ),
  );
}

void main() {
  group('PipelineAuditLogger', () {
    late PipelineAuditLogger logger;

    setUp(() {
      logger = PipelineAuditLogger(traceId: 'TRACE-TEST-001');
    });

    test('initial state is correct', () {
      expect(logger.traceId, 'TRACE-TEST-001');
      expect(logger.totalInputCases, 0);
      expect(logger.finalizedCases, 0);
      expect(logger.repairedCases, 0);
      expect(logger.rejectedCount, 0);
      expect(logger.rejectedCases, isEmpty);
      expect(logger.repairLog, isEmpty);
      expect(logger.fallbackTriggers, isEmpty);
      expect(logger.diversityBalance, isEmpty);
      expect(logger.averageConfidence, 0.0);
    });

    test('log adds event', () {
      final event = PipelineEvent(
        stage: 'parsing',
        action: 'parse',
        beforeCount: 5,
        afterCount: 3,
        traceId: 'TRACE-TEST-001',
        timestamp: 1000,
        metadata: {},
      );
      logger.log(event);
    });

    test('logTimeline adds entry', () {
      logger.logTimeline('Custom event');
    });

    test('logRejected adds rejected case info', () {
      logger.logRejected(
        RejectedCaseInfo(title: 'Test', reason: 'Bad title', stage: 'validation'),
      );
      expect(logger.rejectedCases, hasLength(1));
      expect(logger.rejectedCases.first.title, 'Test');
      expect(logger.rejectedCount, 1);
      expect(logger.finalizedCases, -1);
    });

    test('logRepair adds repair log entry', () {
      logger.logRepair(testCaseId: 'TC-001', operation: 'Fixed title');
      expect(logger.repairLog, hasLength(1));
      expect(logger.repairLog.first, 'TC-001 -> Fixed title');
      expect(logger.repairedCases, 1);
    });

    test('logFallback adds fallback trigger', () {
      logger.logFallback('AI returned empty');
      expect(logger.fallbackTriggers, hasLength(1));
      expect(logger.fallbackTriggers.first, 'AI returned empty');
    });

    test('logSecurityEvent adds security event', () {
      logger.logSecurityEvent('Injection attempt');
    });

    test('logValidatorEvent adds validator event', () {
      logger.logValidatorEvent('High rejection rate');
    });

    group('recordCases', () {
      test('records cases and computes averages', () {
        final cases = [
          _makeCase(title: 'TC1', semanticProfile: 'security', confidence: 0.9),
          _makeCase(title: 'TC2', semanticProfile: 'functional', confidence: 0.8),
        ];
        logger.recordCases(cases);
        expect(logger.totalInputCases, 2);
        expect(logger.averageConfidence, closeTo(0.85, 0.001));
        expect(logger.diversityBalance, {'security': 1, 'functional': 1});
      });

      test('handles empty cases', () {
        logger.recordCases([]);
        expect(logger.totalInputCases, 0);
        expect(logger.averageConfidence, 0.0);
      });

      test('accumulates diversity balance', () {
        final cases = [
          _makeCase(semanticProfile: 'security'),
          _makeCase(semanticProfile: 'security'),
          _makeCase(semanticProfile: 'functional'),
        ];
        logger.recordCases(cases);
        expect(logger.diversityBalance, {'security': 2, 'functional': 1});
      });
    });

    test('buildReport creates PipelineAuditReport', () {
      logger.logRejected(
        RejectedCaseInfo(title: 'T1', reason: 'Bad', stage: 'S'),
      );
      logger.logRepair(testCaseId: 'TC-1', operation: 'Fix');
      logger.logFallback('Fallback reason');
      logger.recordCases([_makeCase(semanticProfile: 'security')]);

      final report = logger.buildReport(missingIntentIds: ['intent-1']);
      expect(report.traceId, 'TRACE-TEST-001');
      expect(report.rejectedCases, hasLength(1));
      expect(report.repairLog, hasLength(1));
      expect(report.fallbackTriggers, hasLength(1));
      expect(report.diversityBalance, {'security': 1});
      expect(report.totalInputCases, 1);
      expect(report.missingIntentIds, ['intent-1']);
    });

    test('buildReport without missingIntentIds', () {
      final report = logger.buildReport();
      expect(report.missingIntentIds, isNull);
    });

    test('toJson produces correct structure', () {
      logger.logRejected(
        RejectedCaseInfo(title: 'T1', reason: 'Bad', stage: 'S'),
      );
      logger.logRepair(testCaseId: 'TC-1', operation: 'Fix');
      logger.logFallback('Fallback');
      logger.logSecurityEvent('XSS');
      logger.logValidatorEvent('High reject');

      final json = logger.toJson();
      expect(json['traceId'], 'TRACE-TEST-001');
      expect(json['rejectedCases'], hasLength(1));
      expect(json['repairLog'], hasLength(1));
      expect(json['fallbackTriggers'], hasLength(1));
      expect(json['securityEvents'], ['XSS']);
      expect(json['validatorEvents'], ['High reject']);
      expect(json['timeline'], isNotEmpty);
      expect(json['events'], isEmpty);
      expect(json['processedCases'], 0);
    });

    test('toJson includes timeline entries', () {
      logger.logTimeline('Test timeline');
      final json = logger.toJson();
      expect(json['timeline'], hasLength(1));
      expect(json['timeline'].first, contains('Test timeline'));
    });
  });
}
