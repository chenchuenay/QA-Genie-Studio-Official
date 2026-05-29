import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/humanization/qa_heuristics_engine.dart';
// ============================================================
// lib/engine/validators/structural_validator.dart
// ============================================================

class StructuralValidationResult {
  final List<WorkingCase> validCases;
  final Map<int, String> rejectedReasons;

  const StructuralValidationResult({
    required this.validCases,
    required this.rejectedReasons,
  });
}

class StructuralValidator {
  const StructuralValidator();

  StructuralValidationResult validate(
    List<WorkingCase> cases,
    Function(RejectedCaseInfo) logRejected,
  ) {
    final valid = <WorkingCase>[];
    final rejected = <int, String>{};

    for (int index = 0; index < cases.length; index++) {
      final tc = cases[index];

      final reason = _validate(tc);

      if (reason == null) {
        valid.add(tc.copy());
      } else {
        rejected[index] = reason;

        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: reason,
            stage: 'StructuralValidation',
          ),
        );
      }
    }

    return StructuralValidationResult(
      validCases: valid,
      rejectedReasons: rejected,
    );
  }

  String? _validate(WorkingCase tc) {
    if (tc.title.trim().isEmpty) {
      return 'Hard Fail: Title is empty.';
    }

    if (tc.title.toLowerCase() == 'missing title') {
      return 'Hard Fail: Placeholder title detected.';
    }

    if (tc.id.trim().isEmpty) {
      return 'Hard Fail: Missing testcase ID.';
    }

    if (tc.expectedResult.trim().isEmpty) {
      return 'Hard Fail: Missing expected result.';
    }

    if (tc.steps.isEmpty) {
      return 'Hard Fail: No steps found.';
    }

    final meaningfulSteps = tc.steps
        .where(QaHeuristicsEngine.isMeaningfulStep)
        .length;

    if (meaningfulSteps == 0) {
      return 'Hard Fail: No meaningful execution steps.';
    }

    for (int i = 0; i < tc.steps.length; i++) {
      final step = tc.steps[i];
      if (step.action.trim().isEmpty) {
        return 'Hard Fail: Step ${i + 1} action is empty.';
      }
      if (step.expected.trim().isEmpty) {
        return 'Hard Fail: Step ${i + 1} expected result is empty.';
      }
    }

    return null;
  }
}
