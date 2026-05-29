import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

class FinalizedTestCaseAdapter {
  static List<TestCaseModel> toLegacyList(List<FinalizedTestCase> cases) {
    return cases.map(toLegacy).toList();
  }

  static TestCaseModel toLegacy(FinalizedTestCase tc) {
    final legacySteps = tc.steps.map((step) {
      return TestStep(
        action: step.action,
        data: step.data,
        expected: step.expected,
      );
    }).toList();

    return TestCaseModel(
      source: tc.source,
      dbId: tc.dbId,
      id: tc.id,
      title: tc.title,
      module: tc.module,
      feature: tc.feature,
      platform: tc.platform,
      priority: tc.priority,
      type: tc.type,
      preconditions: List<String>.from(tc.preconditions),
      steps: legacySteps,
      expectedResult: tc.expectedResult,
      actualResult: tc.actualResult,
      status: tc.status,
      intent: null,
    );
  }

  static List<FinalizedTestCase> fromLegacyList(List<TestCaseModel> models) {
    return models.map(fromLegacy).toList();
  }

  static FinalizedTestCase fromLegacy(TestCaseModel legacy) {
    final canonicalSteps = legacy.steps.map((step) {
      return TestStep(
        action: step.action,
        data: step.data,
        expected: step.expected,
      );
    }).toList();

    return FinalizedTestCase(
      dbId: legacy.dbId,
      id: legacy.id,
      title: legacy.title,
      preconditions: List<String>.from(legacy.preconditions),
      testData: '',
      steps: canonicalSteps,
      expectedResult: legacy.expectedResult,
      actualResult: legacy.actualResult,
      priority: legacy.priority,
      status: legacy.status,
      type: legacy.type,
      module: legacy.module,
      feature: legacy.feature,
      platform: legacy.platform,
      source: legacy.source,
    );
  }
}
