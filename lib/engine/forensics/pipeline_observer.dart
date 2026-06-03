/// lib/engine/forensics/pipeline_observer.dart
library;

/// Observer for the AI generation pipeline.
/// Used to capture forensic data without direct filesystem access.
abstract class PipelineObserver {
  void onStageEvent(String category, Map<String, dynamic> data);
  void onTraceEvent(String message);
}

/// Default observer that does nothing. Safe for production.
class NoOpPipelineObserver implements PipelineObserver {
  const NoOpPipelineObserver();
  @override
  void onStageEvent(String category, Map<String, dynamic> data) {}
  @override
  void onTraceEvent(String message) {}
}

/// Global provider for the pipeline observer.
/// Production defaults to NoOp.
class PipelineForensics {
  static PipelineObserver _instance = const NoOpPipelineObserver();

  static PipelineObserver get instance => _instance;

  static void setObserver(PipelineObserver observer) {
    _instance = observer;
  }
}
