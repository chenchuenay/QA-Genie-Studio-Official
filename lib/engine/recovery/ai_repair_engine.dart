import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/test_step.dart';

class AiRepairEngine {
  List<WorkingCase> repair(List<WorkingCase> cases, int targetCount) {
    for (final tc in cases) {
      _repairTitle(tc);
      _repairExpectedResult(tc);
      _repairSteps(tc);
      _repairPreconditions(tc);
      _repairTestData(tc);
    }
    return cases;
  }

  void _repairTitle(WorkingCase tc) {
    if (tc.title.trim().isEmpty) {
      tc.title = '${tc.feature} - ${tc.categoryLock} scenario';
    }
  }

  void _repairExpectedResult(WorkingCase tc) {
    if (tc.expectedResult.trim().isEmpty) {
      switch (tc.categoryLock.toLowerCase()) {
        case 'positive':
          tc.expectedResult = 'Operation completes successfully';
          break;
        case 'negative':
          tc.expectedResult = 'System rejects the request with a clear error message';
          break;
        case 'security':
          tc.expectedResult = 'Malicious input is sanitized or rejected';
          break;
        case 'validation':
          tc.expectedResult = 'Inline validation errors appear for each invalid field';
          break;
        case 'boundary':
          tc.expectedResult = 'System handles boundary value gracefully';
          break;
        case 'session':
          tc.expectedResult = 'API returns 401 Unauthorized; user is redirected to login';
          break;
        default:
          tc.expectedResult = 'Operation completes as expected';
      }
    }
  }

  void _repairSteps(WorkingCase tc) {
    if (tc.steps.isEmpty) {
      tc.steps = [
        TestStep(
          action: 'Execute action for ${tc.feature}',
          data: tc.testData,
          expected: tc.expectedResult,
        ),
      ];
    } else {
      for (int i = 0; i < tc.steps.length; i++) {
        final step = tc.steps[i];
        if (step.action.trim().isEmpty) {
          step.action = 'Perform step ${i + 1}';
        }
        if (step.expected.trim().isEmpty) {
          step.expected = tc.expectedResult.isNotEmpty
              ? tc.expectedResult
              : 'Step $i completes successfully';
        }
      }
    }
  }

  void _repairPreconditions(WorkingCase tc) {
    if (tc.preconditions.isEmpty) {
      tc.preconditions = [
        'User is authenticated with an active session',
        'User is on the ${tc.feature} screen',
      ];
    }
  }

  void _repairTestData(WorkingCase tc) {
    if (tc.testData.trim().isEmpty) {
      tc.testData = 'Valid input data for ${tc.feature}';
    }
  }
}
