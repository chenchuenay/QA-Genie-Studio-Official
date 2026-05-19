import 'package:qa_genie/engine/models/pipeline_models.dart';

class ExportSafetyResult {
  final bool isSuccessful;
  final List<String> errors;
  ExportSafetyResult(this.isSuccessful, this.errors);
}

class ExportSafetyValidator {
  ExportSafetyResult validate(List<WorkingCase> cases) {
    final errors = <String>[];

    if (cases.isEmpty) {
      errors.add('Schema Error: Compilation yielded zero cases.');
      return ExportSafetyResult(false, errors);
    }

    for (var i = 0; i < cases.length; i++) {
      final tc = cases[i];
      final prefix = 'Case #${i + 1} ("${tc.title}")';

      if (tc.id.isEmpty) errors.add('$prefix: missing ID');
      if (tc.title.isEmpty) errors.add('$prefix: missing title');
      if (tc.steps.isEmpty) errors.add('$prefix: missing steps');
      if (tc.expectedResult.isEmpty)
        errors.add('$prefix: missing expected result');

      // Step level integrity
      for (var j = 0; j < tc.steps.length; j++) {
        if (tc.steps[j].action.isEmpty)
          errors.add('$prefix: step ${j + 1} missing action');
        if (tc.steps[j].expected.isEmpty)
          errors.add('$prefix: step ${j + 1} missing expected');
      }
    }

    return ExportSafetyResult(errors.isEmpty, errors);
  }
}
