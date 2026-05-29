import 'package:qa_genie/engine/models/pipeline_models.dart';
// lib/engine/validators/contracts/pipeline_contract_validator.dart

class PipelineContractValidator {
  const PipelineContractValidator();

  bool validate(WorkingCase testCase) {
    if (!_hasValidIdentity(testCase)) {
      return false;
    }

    if (!_hasValidSteps(testCase)) {
      return false;
    }

    if (!_hasExpectedResult(testCase)) {
      return false;
    }

    if (!_hasUniqueActions(testCase)) {
      return false;
    }

    return true;
  }

  bool _hasValidIdentity(WorkingCase testCase) {
    return testCase.id.trim().isNotEmpty && testCase.title.trim().isNotEmpty;
  }

  bool _hasValidSteps(WorkingCase testCase) {
    if (testCase.steps.isEmpty) {
      return false;
    }

    return testCase.steps.every(
      (step) =>
          step.action.trim().isNotEmpty && step.expected.trim().isNotEmpty,
    );
  }

  bool _hasExpectedResult(WorkingCase testCase) {
    return testCase.expectedResult.trim().isNotEmpty;
  }

  bool _hasUniqueActions(WorkingCase testCase) {
    final actions = testCase.steps.map((e) => e.action.trim()).toList();

    return actions.toSet().length == actions.length;
  }
}
