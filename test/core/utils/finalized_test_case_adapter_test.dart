import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/utils/finalized_test_case_adapter.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/data/models/test_case_model.dart';

void main() {
  final step = TestStep(action: 'Click login', data: 'admin@demo.com', expected: 'Dashboard');
  final tc = FinalizedTestCase(
    dbId: 1, id: 'TC-001', title: 'Login test',
    preconditions: ['User is authenticated'], testData: '',
    steps: [step], expectedResult: 'Dashboard loads',
    actualResult: '', priority: 'High', status: 'Not Executed',
    type: 'positive', module: 'Auth', feature: 'Login',
    platform: 'Web', source: CaseSource.ai,
  );

  group('FinalizedTestCaseAdapter', () {
    test('toLegacy converts to TestCaseModel', () {
      final model = FinalizedTestCaseAdapter.toLegacy(tc);
      expect(model, isA<TestCaseModel>());
      expect(model.id, 'TC-001');
      expect(model.title, 'Login test');
      expect(model.source, CaseSource.ai);
      expect(model.dbId, 1);
    });

    test('fromLegacy converts back to FinalizedTestCase', () {
      final model = FinalizedTestCaseAdapter.toLegacy(tc);
      final restored = FinalizedTestCaseAdapter.fromLegacy(model);
      expect(restored.id, tc.id);
      expect(restored.title, tc.title);
      expect(restored.module, tc.module);
      expect(restored.feature, tc.feature);
      expect(restored.platform, tc.platform);
      expect(restored.priority, tc.priority);
      expect(restored.type, tc.type);
      expect(restored.source, tc.source);
    });

    test('roundtrip preserves all fields', () {
      final model = FinalizedTestCaseAdapter.toLegacy(tc);
      final restored = FinalizedTestCaseAdapter.fromLegacy(model);
      expect(restored.id, tc.id);
      expect(restored.title, tc.title);
      expect(restored.preconditions, tc.preconditions);
      expect(restored.steps.length, tc.steps.length);
      expect(restored.steps[0].action, tc.steps[0].action);
      expect(restored.expectedResult, tc.expectedResult);
      expect(restored.dbId, tc.dbId);
    });

    test('toLegacyList converts list', () {
      final models = FinalizedTestCaseAdapter.toLegacyList([tc, tc]);
      expect(models.length, 2);
    });

    test('fromLegacyList converts list', () {
      final models = FinalizedTestCaseAdapter.toLegacyList([tc]);
      final restored = FinalizedTestCaseAdapter.fromLegacyList(models);
      expect(restored.length, 1);
    });
  });
}
