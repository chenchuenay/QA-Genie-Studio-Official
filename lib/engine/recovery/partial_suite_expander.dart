import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/recovery/deterministic_case_generator.dart';

class PartialSuiteExpander {
  final DeterministicCaseGenerator deterministicGenerator;

  PartialSuiteExpander({required this.deterministicGenerator});

  List<WorkingCase> expand({
    required List<WorkingCase> existingCases,
    required List<String> missingIntentIds,
    required GenerationRequest request,
  }) {
    if (missingIntentIds.isEmpty) return existingCases;
    final generated = deterministicGenerator.generateByIntentIds(
      request: request,
      intentIds: missingIntentIds,
    );
    return [...existingCases, ...generated];
  }
}