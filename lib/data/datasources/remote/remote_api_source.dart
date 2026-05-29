import 'package:qa_genie/core/network/api_client.dart';
import 'package:qa_genie/data/dto/generation_dto.dart';
import 'package:qa_genie/engine/planners/scenario_planner.dart';
import 'package:qa_genie/engine/prompts/prompt_composer.dart';

class RemoteApiSource {
  const RemoteApiSource();

  Future<String> generateTestCases({
    required GenerationDto dto,
  }) async {
    final planner = ScenarioPlanner(
      module: dto.module,
      feature: dto.feature,
      platform: dto.platform,
      mode: dto.mode,
      count: dto.count,
      domain: dto.domain,
    );

    final skeletons = planner.generateSkeletons();

    final prompt = PromptComposer.compose(
      module: dto.module,
      feature: dto.feature,
      platform: dto.platform,
      skeletons: skeletons,
      constraints: dto.constraints,
      domain: dto.domain,
    );

    return ApiClient.generate(
      prompt: prompt,
      traceId: dto.traceId,
    );
  }
}