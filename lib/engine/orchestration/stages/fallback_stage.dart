import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/recovery/partial_suite_expander.dart';
import 'package:qa_genie/engine/recovery/deterministic_case_generator.dart';

class FallbackStage {
  final DeterministicCaseGenerator generator;
  final PartialSuiteExpander expander;

  const FallbackStage({
    required this.generator,
    required this.expander,
  });

  List<WorkingCase> generateFullFallback({
    required GenerationRequest request,
    required int count,
  }) {
    return generator.generate(request: request, count: count);
  }

  List<WorkingCase> expandPartialSuite({
    required GenerationRequest request,
    required List<WorkingCase> existing,
    required List<String> missingIntentIds,
  }) {
    return expander.expand(
      existingCases: existing,
      missingIntentIds: missingIntentIds,
      request: request,
    );
  }
}