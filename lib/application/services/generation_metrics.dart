class GenerationMetrics {
  final int aiGenerated;
  final int aiAccepted;
  final int repairedCount;
  final int filteredCount;
  final int aiCalls;
  final bool aiFailure;
  final String? aiFailureReason;
  double get aiAcceptanceRatio =>
      aiGenerated > 0 ? (aiAccepted / aiGenerated).clamp(0.0, 1.0) : 0.0;
  double get deterministicShare {
    final total = aiAccepted + repairedCount;
    if (total <= 0) return 1.0;
    return (repairedCount / total).clamp(0.0, 1.0);
  }

  const GenerationMetrics({
    this.aiGenerated = 0,
    this.aiAccepted = 0,
    this.repairedCount = 0,
    this.filteredCount = 0,
    this.aiCalls = 0,
    this.aiFailure = false,
    this.aiFailureReason,
  });

  @override
  String toString() =>
      'AI gen: $aiGenerated, accepted: $aiAccepted (${(aiAcceptanceRatio * 100).toStringAsFixed(0)}%), repaired: $repairedCount, filtered: $filteredCount, calls: $aiCalls, aiFailure: $aiFailure';
}
