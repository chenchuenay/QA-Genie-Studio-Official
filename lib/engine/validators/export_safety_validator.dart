import 'package:qa_genie/engine/models/pipeline_models.dart';
// ============================================================
// lib/engine/validators/export_safety_validator.dart
// ============================================================

class ExportSafetyResult {
  final bool isSuccessful;
  final List<String> errors;

  const ExportSafetyResult(this.isSuccessful, this.errors);
}

class ExportSafetyValidator {
  const ExportSafetyValidator();

  ExportSafetyResult validate(List<WorkingCase> cases) {
    final errors = <String>[];

    if (cases.isEmpty) {
      errors.add('Schema Error: Pipeline returned zero finalized cases.');

      return ExportSafetyResult(false, errors);
    }

    for (int i = 0; i < cases.length; i++) {
      final tc = cases[i];

      final prefix = 'Case #${i + 1} ("${tc.title}")';

      if (tc.id.trim().isEmpty) {
        errors.add('$prefix: missing ID');
      }

      if (tc.title.trim().isEmpty) {
        errors.add('$prefix: missing title');
      }

      if (tc.expectedResult.trim().isEmpty) {
        errors.add('$prefix: missing expected result');
      }

      if (tc.steps.isEmpty) {
        errors.add('$prefix: missing steps');
      }

      for (int j = 0; j < tc.steps.length; j++) {
        final step = tc.steps[j];

        if (step.action.trim().isEmpty) {
          errors.add('$prefix: step ${j + 1} missing action');
        }

        if (step.expected.trim().isEmpty) {
          errors.add('$prefix: step ${j + 1} missing expected result');
        }
      }

      if (_containsInjection(tc.title)) {
        errors.add('$prefix: unsafe title detected');
      }

      if (_containsInjection(tc.expectedResult)) {
        errors.add('$prefix: unsafe expected result detected');
      }
    }

    return ExportSafetyResult(errors.isEmpty, errors);
  }

  bool _containsInjection(String text) {
    final lower = text.toLowerCase();

    return lower.contains('<script') ||
        lower.contains('</script>') ||
        lower.contains('drop table') ||
        RegExp(r'(?<![a-zA-Z])--').hasMatch(lower) ||
        lower.contains(';--');
  }
}
