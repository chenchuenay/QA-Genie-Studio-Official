import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/engine/adapters/working_case_adapter.dart';

void main() {
  group('WorkingCaseAdapter', () {
    FinalizedTestCase _makeTestCase({
      String type = 'Positive',
      String module = 'Auth',
      String feature = 'Login',
      String platform = 'Mobile',
    }) {
      return FinalizedTestCase(
        id: 'tc-1',
        title: 'Test login',
        preconditions: ['User is registered'],
        testData: 'user@example.com / password123',
        steps: [
          TestStep(action: 'Enter email', data: 'user@example.com', expected: 'Field filled'),
          TestStep(action: 'Enter password', data: 'password123', expected: 'Field filled'),
          TestStep(action: 'Tap login', data: '', expected: 'Login successful'),
        ],
        expectedResult: 'User is logged in',
        actualResult: '',
        priority: 'High',
        status: 'Not Executed',
        type: type,
        module: module,
        feature: feature,
        platform: platform,
        source: CaseSource.ai,
      );
    }

    test('fromFinalizedTestCase maps all fields correctly', () {
      final tc = _makeTestCase();
      final wc = WorkingCaseAdapter.fromFinalizedTestCase(tc, traceId: 'trace-1');

      expect(wc.id, tc.id);
      expect(wc.title, tc.title);
      expect(wc.module, tc.module);
      expect(wc.feature, tc.feature);
      expect(wc.platform, tc.platform);
      expect(wc.priority, tc.priority);
      expect(wc.type, tc.type);
      expect(wc.categoryLock, 'positive');
      expect(wc.constraints, '');
      expect(wc.preconditions, tc.preconditions);
      expect(wc.testData, tc.testData);
      expect(wc.steps.length, tc.steps.length);
      expect(wc.steps[0].action, tc.steps[0].action);
      expect(wc.steps[0].data, tc.steps[0].data);
      expect(wc.steps[0].expected, tc.steps[0].expected);
      expect(wc.expectedResult, tc.expectedResult);
      expect(wc.actualResult, tc.actualResult);
      expect(wc.status, tc.status);
      expect(wc.metadata.source, CaseSource.ai);
      expect(wc.metadata.traceId, 'trace-1');
      expect(wc.metadata.confidenceScore, 1.0);
      expect(wc.intentId, '');
    });

    test('fromFinalizedTestCase maps type to categoryLock', () {
      final typeMapping = {
        'Positive': 'positive',
        'Negative': 'negative',
        'Validation': 'validation',
        'Boundary': 'boundary',
        'Security': 'security',
      };
      for (final entry in typeMapping.entries) {
        final tc = _makeTestCase(type: entry.key);
        final wc = WorkingCaseAdapter.fromFinalizedTestCase(tc, traceId: 't1');
        expect(wc.categoryLock, entry.value, reason: 'Type ${entry.key} should map to ${entry.value}');
      }
    });

    test('fromFinalizedTestCase maps unknown type to positive', () {
      final tc = _makeTestCase(type: 'Unknown');
      final wc = WorkingCaseAdapter.fromFinalizedTestCase(tc, traceId: 't1');
      expect(wc.categoryLock, 'positive');
    });

    test('fromFinalizedTestCase handles case-insensitive type', () {
      final tc = _makeTestCase(type: 'negative');
      final wc = WorkingCaseAdapter.fromFinalizedTestCase(tc, traceId: 't1');
      expect(wc.categoryLock, 'negative');
    });
  });
}
