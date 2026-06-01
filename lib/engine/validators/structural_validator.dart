import 'package:qa_genie/engine/models/pipeline_models.dart';

class StructuralValidationResult {
  final bool isValid;
  final String? reason;
  const StructuralValidationResult({required this.isValid, this.reason});
}

class StructuralValidator {
  const StructuralValidator();

  StructuralValidationResult validateSingle(WorkingCase tc) {
    if (tc.title.trim().isEmpty) return const StructuralValidationResult(isValid: false, reason: 'Title is empty');
    if (tc.id.trim().isEmpty) return const StructuralValidationResult(isValid: false, reason: 'Missing testcase ID');
    if (tc.expectedResult.trim().isEmpty) return const StructuralValidationResult(isValid: false, reason: 'Missing expected result');
    if (tc.steps.isEmpty) return const StructuralValidationResult(isValid: false, reason: 'No steps found');
    for (int i = 0; i < tc.steps.length; i++) {
      final step = tc.steps[i];
      if (step.action.trim().isEmpty) return StructuralValidationResult(isValid: false, reason: 'Step ${i + 1} action is empty');
      if (step.expected.trim().isEmpty) return StructuralValidationResult(isValid: false, reason: 'Step ${i + 1} expected result is empty');
    }
    return const StructuralValidationResult(isValid: true);
  }
}