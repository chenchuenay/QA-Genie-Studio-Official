import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/recovery/partial_suite_expander.dart';
import 'package:qa_genie/engine/recovery/deterministic_case_generator.dart';
// lib/engine/orchestration/stages/fallback_stage.dart

class FallbackStage {
  final DeterministicCaseGenerator _generator;

  final PartialSuiteExpander _expander;

  const FallbackStage({
    required DeterministicCaseGenerator generator,

    required PartialSuiteExpander expander,
  }) : _generator = generator,

       _expander = expander;

  List<WorkingCase> generateFullFallback({
    required GenerationRequest request,
    required int count,
  }) {
    return _generator.generate(
      request: request,
      count: count,
    );
  }

  List<WorkingCase> expandPartialSuite({
    required GenerationRequest request,
    required List<WorkingCase> existing,
    required int targetCount,
  }) {
    return _expander.expand(
      request: request,
      existingCases: existing,
      targetCount: targetCount,
    );
  }
}
