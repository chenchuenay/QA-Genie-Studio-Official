class GenerationMetrics {
  final int aiGenerated;
  final int aiAccepted;
  final int repairedCount;
  final int filteredCount;
  final int aiCalls;
  final bool aiFailure;
  final String? aiFailureReason;

  /// Exported suite: cases still tagged [CaseSource.ai] (LLM-originated body).
  final int finalAiOriginCount;

  /// Exported suite: deterministic repair / planner-enriched cases [CaseSource.repairedAi].
  final int finalDeterministicOriginCount;

  /// Exported suite: template / emergency / full fallback [CaseSource.fallback].
  final int fallbackInjectedCount;

  double get aiAcceptanceRatio =>
      aiGenerated > 0 ? (aiAccepted / aiGenerated).clamp(0.0, 1.0) : 0.0;

  double get deterministicShare {
    final total = aiAccepted + repairedCount;
    if (total <= 0) return 1.0;
    return (repairedCount / total).clamp(0.0, 1.0);
  }

  /// Share of exported cases that preserve raw AI structure (vs repair/fallback).
  double get aiUsefulnessRatio {
    final n = finalAiOriginCount +
        finalDeterministicOriginCount +
        fallbackInjectedCount;
    if (n <= 0) return 0.0;
    return (finalAiOriginCount / n).clamp(0.0, 1.0);
  }

  /// Share of exported cases that leaned on deterministic or template recovery.
  double get deterministicAssistedRatio {
    final n = finalAiOriginCount +
        finalDeterministicOriginCount +
        fallbackInjectedCount;
    if (n <= 0) return 1.0;
    return ((finalDeterministicOriginCount + fallbackInjectedCount) / n)
        .clamp(0.0, 1.0);
  }

  const GenerationMetrics({
    this.aiGenerated = 0,
    this.aiAccepted = 0,
    this.repairedCount = 0,
    this.filteredCount = 0,
    this.aiCalls = 0,
    this.aiFailure = false,
    this.aiFailureReason,
    this.finalAiOriginCount = 0,
    this.finalDeterministicOriginCount = 0,
    this.fallbackInjectedCount = 0,
  });

  @override
  String toString() =>
      'AI gen: $aiGenerated, accepted: $aiAccepted (${(aiAcceptanceRatio * 100).toStringAsFixed(0)}%), '
      'repaired: $repairedCount, filtered: $filteredCount, calls: $aiCalls, '
      'failure: $aiFailure | lineage: ai=$finalAiOriginCount det=$finalDeterministicOriginCount '
      'fb=$fallbackInjectedCount usefulness=${(aiUsefulnessRatio * 100).toStringAsFixed(0)}%';
}
