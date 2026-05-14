class PipelineConfig {
  // Performance Limits
  final int maxAuditLogEntries;
  final int maxRepairHistoryEntries;
  final Duration pipelineTimeout;
  
  // Execution Budgets
  final int maxRepairAttempts;
  final int maxRecoveryAttempts;
  final int maxDedupPasses;
  
  // Quality Thresholds
  final double minConfidenceThreshold;
  final double fallbackEscalationThreshold;

  const PipelineConfig({
    this.maxAuditLogEntries = 100,
    this.maxRepairHistoryEntries = 20,
    this.pipelineTimeout = const Duration(seconds: 30),
    this.maxRepairAttempts = 3,
    this.maxRecoveryAttempts = 50,
    this.maxDedupPasses = 5,
    this.minConfidenceThreshold = 0.4,
    this.fallbackEscalationThreshold = 0.6,
  });

  static const PipelineConfig production = PipelineConfig();
  static const PipelineConfig fastTrack = PipelineConfig(
    pipelineTimeout: Duration(seconds: 10),
    maxRecoveryAttempts: 20,
  );
}
