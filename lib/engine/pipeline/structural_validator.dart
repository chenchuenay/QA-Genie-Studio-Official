import 'package:qa_genie/engine/pipeline/models/pipeline_models.dart';
import 'package:qa_genie/engine/pipeline/generation_context.dart';

class StructuralValidationResult {
  final List<WorkingCase> validCases;
  final Map<int, String> rejectedReasons;

  StructuralValidationResult({
    required this.validCases,
    required this.rejectedReasons,
  });
}

class StructuralValidator {
  StructuralValidationResult validate(GenerationContext context, List<WorkingCase> cases) {
    final valid = <WorkingCase>[];
    final rejected = <int, String>{};

    for (var index = 0; index < cases.length; index++) {
      final tc = cases[index];
      final reason = _validate(tc);
      if (reason == null) {
        valid.add(tc.copy());
      } else {
        rejected[index] = reason;
        context.logRejected(RejectedCaseInfo(
          title: tc.title,
          reason: reason,
          stage: 'StructuralValidation',
        ));
      }
    }
    return StructuralValidationResult(
      validCases: valid,
      rejectedReasons: rejected,
    );
  }

  /// Hard-fail ONLY rules.
  String? _validate(WorkingCase tc) {
    if (tc.title.trim().isEmpty || tc.title == 'Missing Title') {
       return 'Hard Fail: Title is missing or contains default placeholder.';
    }
    
    if (tc.steps.length < 3) {
      return 'Hard Fail: Insufficient steps: found ${tc.steps.length}, minimum required is 3.';
    }

    if (tc.expectedResult.trim().isEmpty) {
      return 'Hard Fail: Expected result is missing or empty.';
    }

    if (tc.id.trim().isEmpty) {
      return 'Hard Fail: ID is missing.';
    }

    return null;
  }
}
