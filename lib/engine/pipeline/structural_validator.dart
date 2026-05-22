import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/qa_heuristics_engine.dart';

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
    if (tc.title.trim().isEmpty || tc.title.toLowerCase() == 'missing title') {
      return 'Hard Fail: Title is empty or placeholder.';
    }

    if (tc.id.trim().isEmpty) {
      return 'Hard Fail: ID is missing.';
    }

    if (tc.expectedResult.trim().isEmpty) {
      return 'Hard Fail: Expected result is empty.';
    }

    // NEW: Meaningfulness validation
    if (tc.steps.isEmpty) {
      return 'Hard Fail: No steps provided.';
    }
    
    final meaningfulCount = tc.steps.where(QaHeuristicsEngine.isMeaningfulStep).length;
    if (meaningfulCount == 0) {
      return 'Hard Fail: No meaningful steps found. Testcase intent is ambiguous.';
    }

    for (int i = 0; i < tc.steps.length; i++) {
      final step = tc.steps[i];
      if (step.action.trim().isEmpty || step.expected.trim().isEmpty) {
        return 'Hard Fail: Step ${i + 1} structure is incomplete.';
      }
    }

    return null;
  }
}
