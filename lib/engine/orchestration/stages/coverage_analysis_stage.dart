import 'package:qa_genie/engine/models/pipeline_models.dart';

class CoverageAnalysisStage {
  const CoverageAnalysisStage();

  CoverageAnalysisResult execute({
    required GenerationRequest request,
    required List<WorkingCase> acceptedCases,
  }) {
    final targetItems = request.plan
        .map(_CoveragePlanItem.fromMap)
        .where((item) => item.outcome.isNotEmpty)
        .take(request.requestedCaseCount)
        .toList();

    final targetCategoryCounts = <String, int>{};
    for (final item in targetItems) {
      targetCategoryCounts[item.category] =
          (targetCategoryCounts[item.category] ?? 0) + 1;
    }

    final acceptedCategoryCounts = <String, int>{};
    final acceptedIntentCounts = <String, int>{};
    for (final testCase in acceptedCases) {
      final category = _categoryForCase(testCase);
      acceptedCategoryCounts[category] =
          (acceptedCategoryCounts[category] ?? 0) + 1;

      final intent = _knownIntent(testCase.intentId);
      if (intent != null) {
        acceptedIntentCounts[intent] = (acceptedIntentCounts[intent] ?? 0) + 1;
      }
    }

    final missingCount = (request.requestedCaseCount - acceptedCases.length)
        .clamp(0, 1 << 31)
        .toInt();
    final missingCategoryCounts = <String, int>{};
    for (final entry in targetCategoryCounts.entries) {
      final accepted = acceptedCategoryCounts[entry.key] ?? 0;
      final deficit = entry.value - accepted;
      if (deficit > 0) missingCategoryCounts[entry.key] = deficit;
    }

    final missingOutcomes = _selectMissingOutcomes(
      targetItems: targetItems,
      acceptedIntentCounts: acceptedIntentCounts,
      missingCategoryCounts: missingCategoryCounts,
      limit: missingCount,
    );

    return CoverageAnalysisResult(
      requestedCount: request.requestedCaseCount,
      acceptedAiCount: acceptedCases.length,
      missingCount: missingCount,
      missingOutcomes: missingOutcomes,
      missingCategoryCounts: missingCategoryCounts,
      targetCategoryCounts: targetCategoryCounts,
      acceptedCategoryCounts: acceptedCategoryCounts,
      requiresFullFallback:
          acceptedCases.isEmpty && missingCount == request.requestedCaseCount,
    );
  }

  List<String> _selectMissingOutcomes({
    required List<_CoveragePlanItem> targetItems,
    required Map<String, int> acceptedIntentCounts,
    required Map<String, int> missingCategoryCounts,
    required int limit,
  }) {
    if (limit <= 0) return const [];

    final selected = <String>[];
    final coveredByIntent = Map<String, int>.from(acceptedIntentCounts);
    final remainingCategoryNeeds = Map<String, int>.from(missingCategoryCounts);

    for (final item in targetItems) {
      final coveredCount = coveredByIntent[item.outcome] ?? 0;
      if (coveredCount > 0) {
        coveredByIntent[item.outcome] = coveredCount - 1;
        continue;
      }

      final categoryNeed = remainingCategoryNeeds[item.category] ?? 0;
      if (categoryNeed <= 0) continue;

      selected.add(item.outcome);
      remainingCategoryNeeds[item.category] = categoryNeed - 1;
      if (selected.length == limit) return selected;
    }

    for (final item in targetItems) {
      if (selected.length == limit) break;
      if (selected.contains(item.outcome)) continue;
      selected.add(item.outcome);
    }

    return selected;
  }

  String _categoryForCase(WorkingCase testCase) {
    final locked = testCase.categoryLock.trim();
    if (locked.isNotEmpty) return _normalizeCategory(locked);
    return _normalizeCategory(testCase.type);
  }

  String? _knownIntent(String intentId) {
    final normalized = intentId.trim();
    if (normalized.isEmpty || normalized == '__unknown__') return null;
    return normalized;
  }
}

class CoverageAnalysisResult {
  final int requestedCount;
  final int acceptedAiCount;
  final int missingCount;
  final List<String> missingOutcomes;
  final Map<String, int> missingCategoryCounts;
  final Map<String, int> targetCategoryCounts;
  final Map<String, int> acceptedCategoryCounts;
  final bool requiresFullFallback;

  const CoverageAnalysisResult({
    required this.requestedCount,
    required this.acceptedAiCount,
    required this.missingCount,
    required this.missingOutcomes,
    required this.missingCategoryCounts,
    required this.targetCategoryCounts,
    required this.acceptedCategoryCounts,
    required this.requiresFullFallback,
  });

  bool get needsFallback => missingCount > 0;
}

class _CoveragePlanItem {
  final String outcome;
  final String category;

  const _CoveragePlanItem({required this.outcome, required this.category});

  factory _CoveragePlanItem.fromMap(Map<String, dynamic> map) {
    return _CoveragePlanItem(
      outcome: (map['intent_id'] ?? map['intentId'] ?? '').toString().trim(),
      category: _normalizeCategory(map['category'] ?? map['categoryLock']),
    );
  }
}

String _normalizeCategory(dynamic value) {
  final raw = (value ?? '').toString().trim().toLowerCase();
  if (raw.contains('positive')) return 'positive';
  if (raw.contains('negative')) return 'negative';
  if (raw.contains('validation')) return 'validation';
  if (raw.contains('boundary')) return 'boundary';
  if (raw.contains('security')) return 'security';
  if (raw.contains('session')) return 'session';
  return raw.isEmpty ? 'positive' : raw;
}
