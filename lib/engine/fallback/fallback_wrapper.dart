import 'package:qa_genie/core/security/content_filter.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/engine/orchestrator/deterministic_engine.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

class FallbackWrapper {
  static Future<List<WorkingCase>> generateMissing({
    required GenerationRequest request,
    required int missingCount,
    required List<String> missingOutcomes,
    required int existingCount,
  }) async {
    if (missingCount <= 0) return [];

    final engine = DeterministicEngine(
      module: ContentFilter.sanitizeField(request.module),
      feature: ContentFilter.sanitizeField(request.feature),
      platform: request.platform,
      constraints: ContentFilter.sanitizeField(request.constraints),
      targetCount: missingCount,
      mode: GenerationMode.values.byName(request.generationMode),
    );
    final finalizedCases = await engine.generate();

    return finalizedCases.map((tc) => _toWorkingCase(tc, request)).toList();
  }

  static WorkingCase _toWorkingCase(
    FinalizedTestCase tc,
    GenerationRequest request,
  ) {
    return WorkingCase(
      id: tc.id,
      title: tc.title,
      module: tc.module,
      feature: tc.feature,
      platform: tc.platform,
      priority: tc.priority,
      type: tc.type,
      categoryLock: tc.type.toLowerCase(),
      constraints: request.constraints,
      preconditions: tc.preconditions,
      testData: tc.testData,
      steps: tc.steps
          .map(
            (s) => TestStep(
              action: s.action,
              data: s.data,
              expected: s.expected,
            ),
          )
          .toList(),
      expectedResult: tc.expectedResult,
      actualResult: tc.actualResult,
      status: tc.status,
      metadata: CaseMetadata(
        source: CaseSource.fallback,
        traceId: request.traceId,
        confidenceScore: 0.85,
        repairHistory: [],
        validationIssues: [],
        intentId: 'fallback_${tc.id}',
      ),
      intentId: 'fallback_${tc.id}',
    );
  }
}
