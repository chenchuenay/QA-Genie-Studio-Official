import 'package:qa_genie/engine/generation_metrics.dart';
import 'package:qa_genie/engine/pipeline/models/pipeline_models.dart';
import 'package:qa_genie/engine/pipeline/pipeline_config.dart';

class GenerationContext {
  final String generationSessionId;
  final String module;
  final String feature;
  final String platform;
  final String inferredDomain;
  final int startIndex;
  final int requestedCount;
  final String deterministicSeed;
  final PipelineConfig config;

  final DateTime firstApiCallTimestamp = DateTime.now();
  String? modelUsed;
  int apiCallCount = 0;

  // Metadata & Signals
  final Map<String, dynamic> promptMetadata;
  final Set<String> semanticSignals;
  final Set<String> detectedCategories;
  
  // Pipeline State
  final List<Map<String, dynamic>> skeletons;
  final List<String> warnings;
  final List<String> errors;
  
  // Forensic Audit Streams
  final List<String> apiInvocationLog = [];
  final List<String> repairLog = [];
  final List<String> fallbackLog = [];
  final List<String> escalationLog = [];
  final List<RejectedCaseInfo> rejectedCases = [];
  
  // Intermediate Snapshots (Immutable Transitions)
  String rawApiResponse = '';
  final List<WorkingCase> normalizedCases = [];
  final List<WorkingCase> structurallyValidCases = [];
  final List<WorkingCase> repairedCases = [];
  final List<WorkingCase> semanticallyValidCases = [];
  final List<WorkingCase> deduplicatedCases = [];
  final List<WorkingCase> scoredCases = [];
  final List<FinalizedTestCase> finalCases = [];
  
  GenerationMetrics metrics;
  final Stopwatch _stopwatch = Stopwatch();

  GenerationContext({
    required this.generationSessionId,
    required this.module,
    required this.feature,
    required this.platform,
    required this.inferredDomain,
    required this.startIndex,
    required this.requestedCount,
    required this.deterministicSeed,
    required this.skeletons,
    this.config = PipelineConfig.production,
    GenerationMetrics? metrics,
  }) : promptMetadata = {},
       semanticSignals = {},
       detectedCategories = {},
       warnings = [],
       errors = [],
       metrics = metrics ?? const GenerationMetrics() {
    _stopwatch.start();
  }

  bool get isTimedOut => _stopwatch.elapsed > config.pipelineTimeout;

  // Forensic Logging
  void logApiInvocation(String message) => apiInvocationLog.add(message);
  void logRepair(String message) => repairLog.add(message);
  void logFallback(String message) => fallbackLog.add(message);
  void logEscalation(String message) => escalationLog.add(message);

  void logRejected(RejectedCaseInfo info) {
    if (rejectedCases.length < config.maxAuditLogEntries) {
      rejectedCases.add(info);
    }
  }

  PipelineAuditReport generateAuditReport() {
    double totalConfidence = 0;
    if (scoredCases.isNotEmpty) {
      totalConfidence = scoredCases.map((c) => c.metadata.confidenceScore).reduce((a, b) => a + b) / scoredCases.length;
    }

    final balance = <String, int>{};
    for (final c in scoredCases) {
      balance[c.metadata.semanticProfile] = (balance[c.metadata.semanticProfile] ?? 0) + 1;
    }

    return PipelineAuditReport(
      rejectedCases: List.from(rejectedCases),
      repairLog: List.from(repairLog),
      diversityBalance: balance,
      averageConfidence: totalConfidence,
      fallbackTriggers: List.from(fallbackLog),
    );
  }
}
