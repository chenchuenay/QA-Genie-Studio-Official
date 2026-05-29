class PipelineEvent {
  final String stage;
  final String action;
  final int beforeCount;
  final int afterCount;
  final String traceId;
  final int timestamp;
  final Map<String, dynamic> metadata;

  const PipelineEvent({
    required this.stage,
    required this.action,
    required this.beforeCount,
    required this.afterCount,
    required this.traceId,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'action': action,
      'beforeCount': beforeCount,
      'afterCount': afterCount,
      'traceId': traceId,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}
