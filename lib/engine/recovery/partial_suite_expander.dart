import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/recovery/deterministic_case_generator.dart';
// lib/engine/recovery/partial_suite_expander.dart


class PartialSuiteExpander {
  final DeterministicCaseGenerator deterministicGenerator;

  PartialSuiteExpander({required this.deterministicGenerator});

  List<WorkingCase> expand({
    required GenerationRequest request,
    required List<WorkingCase> existingCases,
    required int targetCount,
  }) {
    if (existingCases.length >= targetCount) {
      return existingCases.take(targetCount).toList();
    }

    final missingCount = targetCount - existingCases.length;

    final generated = deterministicGenerator.generate(
      request: request,
      count: missingCount,
      startIndex: existingCases.length,
    );

    return [...existingCases, ...generated];
  }
}
