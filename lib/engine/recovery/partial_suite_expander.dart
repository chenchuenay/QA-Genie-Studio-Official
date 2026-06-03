import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/recovery/deterministic_case_generator.dart';

class PartialSuiteExpander {
  final DeterministicCaseGenerator deterministicGenerator;

  PartialSuiteExpander({required this.deterministicGenerator});

  List<WorkingCase> generateMissing({
    required GenerationRequest request,
    required List<String> outcomes,
    int startIndex = 0,
  }) {
    return deterministicGenerator.generateByOutcomes(
      request: request,
      outcomes: outcomes,
      startIndex: startIndex,
    );
  }
}
