import 'package:qa_genie/engine/pipeline/generation_context.dart';
import 'package:qa_genie/engine/pipeline/models/pipeline_models.dart';

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
    GenerationContext context,
    List<WorkingCase> cases,
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

        context.logRejected(
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

  /// HARD FAIL ONLY
  /// No AI-quality scoring here.
  /// Only reject cases that can break execution,
  /// exports, rendering, or pipeline integrity.
  String? _validate(WorkingCase tc) {
    // =========================================================
    // TITLE VALIDATION
    // =========================================================

    final title = tc.title.trim();

    if (title.isEmpty) {
      return 'Hard Fail: Title is empty.';
    }

    if (title.toLowerCase() == 'missing title') {
      return 'Hard Fail: Title contains placeholder value.';
    }

    // =========================================================
    // ID VALIDATION
    // =========================================================

    if (tc.id.trim().isEmpty) {
      return 'Hard Fail: ID is missing.';
    }

    // =========================================================
    // EXPECTED RESULT VALIDATION
    // =========================================================

    if (tc.expectedResult.trim().isEmpty) {
      return 'Hard Fail: Expected result is empty.';
    }

    // =========================================================
    // STEP COUNT VALIDATION
    // =========================================================

    if (tc.steps.length < 3) {
      return 'Hard Fail: Minimum 3 steps required. Found ${tc.steps.length}.';
    }

    // =========================================================
    // STEP STRUCTURE VALIDATION
    // =========================================================

    for (int i = 0; i < tc.steps.length; i++) {
      final step = tc.steps[i];

      if (step.action.trim().isEmpty) {
        return 'Hard Fail: Step ${i + 1} action is empty.';
      }

      if (step.expected.trim().isEmpty) {
        return 'Hard Fail: Step ${i + 1} expected result is empty.';
      }
    }

    // =========================================================
    // PASS
    // =========================================================

    return null;
  }
}
