import 'package:qa_genie/data/models/test_case_model.dart';

class ExportValidationResult {
  final bool isValid;
  final List<String> errors;

  const ExportValidationResult({required this.isValid, required this.errors});
}

class ExportValidationService {
  static ExportValidationResult validate(List<TestCaseModel> suite) {
    final errors = <String>[];

    if (suite.isEmpty) {
      errors.add('Suite is empty. Nothing to export.');
      return ExportValidationResult(isValid: false, errors: errors);
    }

    final seenIds = <String>{};

    for (int i = 0; i < suite.length; i++) {
      final tc = suite[i];
      final idx = i + 1;

      if (tc.id.trim().isEmpty) errors.add('Case #$idx: ID is empty.');
      if (seenIds.contains(tc.id.trim())) errors.add('Case #$idx: Duplicate ID "${tc.id}".');
      seenIds.add(tc.id.trim());
      if (tc.title.trim().isEmpty) errors.add('Case #$idx: Title is empty.');
      if (tc.steps.isEmpty) errors.add('Case #$idx ("${tc.title}"): No steps defined.');
      for (int j = 0; j < tc.steps.length; j++) {
        if (tc.steps[j].action.trim().isEmpty) errors.add('Case #$idx ("${tc.title}"), Step ${j + 1}: Action is empty.');
      }
      if (tc.expectedResult.trim().isEmpty) errors.add('Case #$idx ("${tc.title}"): Expected result is empty.');
      if (!['High', 'Medium', 'Low'].contains(tc.priority)) {
        errors.add('Case #$idx ("${tc.title}"): Invalid priority "${tc.priority}".');
      }
    }
    return ExportValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}
