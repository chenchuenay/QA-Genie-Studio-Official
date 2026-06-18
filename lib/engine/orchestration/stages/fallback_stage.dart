import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/adapters/working_case_adapter.dart';
import 'package:qa_genie/engine/orchestrator/deterministic_engine.dart';
import 'package:qa_genie/engine/orchestration/stages/coverage_analysis_stage.dart';

class FallbackStage {
  const FallbackStage();

  Future<List<WorkingCase>> fillMissing({
    required GenerationRequest request,
    required List<WorkingCase> existing,
    required CoverageAnalysisResult coverage,
  }) async {
    if (!coverage.needsFallback) return const [];

    final engine = DeterministicEngine(
      module: request.module,
      feature: request.feature,
      platform: request.platform,
      constraints: request.constraints,
      targetCount: coverage.missingCount,
      mode: GenerationMode.values.byName(request.generationMode),
    );
    final missingFinalized = await engine.generate();
    final missingWorking = missingFinalized
        .map(
          (tc) => WorkingCaseAdapter.fromFinalizedTestCase(
            tc,
            traceId: request.traceId,
          ),
        )
        .toList();
    return missingWorking.take(coverage.missingCount).toList();
  }
}
