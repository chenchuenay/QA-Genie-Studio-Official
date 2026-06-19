import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/orchestration/stages/fallback_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/coverage_analysis_stage.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';

void main() {
  group('FallbackStage', () {
    test('fillMissing returns empty when coverage does not need fallback', () async {
      final stage = const FallbackStage();
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 5,
        traceId: 'trace-1',
      );
      final coverage = CoverageAnalysisResult(
        requestedCount: 5,
        acceptedAiCount: 5,
        missingCount: 0,
        missingOutcomes: [],
        missingCategoryCounts: {},
        targetCategoryCounts: {},
        acceptedCategoryCounts: {},
        requiresFullFallback: false,
      );
      final result = await stage.fillMissing(
        request: request,
        existing: [],
        coverage: coverage,
      );
      expect(result, isEmpty);
    });
  });
}
