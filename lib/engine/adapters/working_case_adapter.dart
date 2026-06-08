import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';

class WorkingCaseAdapter {
  static WorkingCase fromFinalizedTestCase(
    FinalizedTestCase tc, {
    required String traceId,
  }) {
    return WorkingCase(
      id: tc.id,
      title: tc.title,
      module: tc.module,
      feature: tc.feature,
      platform: tc.platform,
      priority: tc.priority,
      type: tc.type,
      categoryLock: _mapCategoryLock(tc.type),
      constraints: '',
      preconditions: tc.preconditions,
      testData: tc.testData,
      steps: tc.steps
          .map(
            (s) => TestStep(
              action: s.action,
              data: s.data,
              expected: s.expected,
            ),
          )
          .toList(),
      expectedResult: tc.expectedResult,
      actualResult: tc.actualResult,
      status: tc.status,
      metadata: CaseMetadata(
        source: tc.source,
        traceId: traceId,
        confidenceScore: 1.0,
        repairHistory: const [],
        validationIssues: const [],
        intentId: '',
      ),
      intentId: '',
    );
  }

  static String _mapCategoryLock(String type) {
    switch (type.toLowerCase()) {
      case 'positive':
        return 'positive';
      case 'negative':
        return 'negative';
      case 'validation':
        return 'validation';
      case 'boundary':
        return 'boundary';
      case 'security':
        return 'security';
      default:
        return 'positive';
    }
  }
}
