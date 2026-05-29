import 'package:qa_genie/data/dto/generation_dto.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/prompts/prompt_composer.dart';
import 'package:qa_genie/engine/planners/scenario_planner.dart';
import 'package:qa_genie/engine/orchestration/pipeline_orchestrator.dart';

class GenerateTestCasesUseCase {
  final PipelineOrchestrator _orchestrator;

  const GenerateTestCasesUseCase({required PipelineOrchestrator orchestrator})
    : _orchestrator = orchestrator;

  Future<GenerationSession> execute({required GenerationDto dto}) async {
    final planner = ScenarioPlanner(
      module: dto.module,
      feature: dto.feature,
      platform: dto.platform,
      mode: dto.mode,
      count: dto.count,
      domain: dto.domain,
      constraints: dto.constraints,
    );

    final skeletons = planner.generateSkeletons();

    final prompt = PromptComposer.compose(
      module: dto.module,
      feature: dto.feature,
      platform: dto.platform,
      skeletons: skeletons,
      domain: dto.domain,
    );

    final request = GenerationRequest(
      module: dto.module,
      feature: dto.feature,
      platform: dto.platform,
      generationMode: dto.mode.name,
      requestedCaseCount: dto.count,
      constraints: dto.constraints,
      domain: dto.domain,
    );

    final result = await _orchestrator.execute(
      prompt: prompt,
      request: request,
    );

    return GenerationSession(
      traceId: result.traceId,
      testCases: result.cases,
      auditReport: result.auditReport,
    );
  }
}
