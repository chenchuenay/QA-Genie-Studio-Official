import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/orchestration/stages/coverage_analysis_stage.dart';
import 'package:qa_genie/engine/recovery/partial_suite_expander.dart';
import 'package:qa_genie/engine/recovery/deterministic_case_generator.dart';

class FallbackStage {
  final DeterministicCaseGenerator generator;
  final PartialSuiteExpander expander;

  const FallbackStage({required this.generator, required this.expander});

  List<WorkingCase> generateFullFallback({
    required GenerationRequest request,
    required int count,
    int startIndex = 0,
  }) {
    return generator.generate(
      request: request,
      count: count,
      startIndex: startIndex,
    );
  }

  List<WorkingCase> fillMissing({
    required GenerationRequest request,
    required List<WorkingCase> existing,
    required CoverageAnalysisResult coverage,
  }) {
    if (!coverage.needsFallback) return const [];

    if (coverage.requiresFullFallback) {
      return generateFullFallback(
        request: request,
        count: coverage.missingCount,
        startIndex: existing.length,
      );
    }

    final generated = <WorkingCase>[];
    final outcomeTargets = coverage.missingOutcomes
        .take(coverage.missingCount)
        .toList();

    if (outcomeTargets.isNotEmpty) {
      generated.addAll(
        expander.generateMissing(
          request: request,
          outcomes: outcomeTargets,
          startIndex: existing.length,
        ),
      );
    }

    final remaining = coverage.missingCount - generated.length;
    if (remaining > 0) {
      final categoryCounts = _limitCategoryCounts(
        coverage.missingCategoryCounts,
        remaining,
      );
      if (categoryCounts.isNotEmpty) {
        generated.addAll(
          generator.generateByCategoryCounts(
            request: request,
            categoryCounts: categoryCounts,
            startIndex: existing.length + generated.length,
          ),
        );
      } else {
        generated.addAll(
          generator.generate(
            request: request,
            count: remaining,
            startIndex: existing.length + generated.length,
          ),
        );
      }
    }

    return generated.take(coverage.missingCount).toList();
  }

  Map<String, int> _limitCategoryCounts(Map<String, int> source, int limit) {
    final limited = <String, int>{};
    var remaining = limit;
    for (final entry in source.entries) {
      if (remaining <= 0) break;
      final count = entry.value < remaining ? entry.value : remaining;
      if (count > 0) {
        limited[entry.key] = count;
        remaining -= count;
      }
    }
    return limited;
  }
}
