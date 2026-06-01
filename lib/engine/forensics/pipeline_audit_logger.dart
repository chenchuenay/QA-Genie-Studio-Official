import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/forensics/models/pipeline_event.dart';

class PipelineAuditLogger {
  final String traceId;
  final DateTime startedAt;

  final List<RejectedCaseInfo> _rejectedCases = [];
  final List<String> _repairLog = [];
  final List<String> _fallbackTriggers = [];
  final List<String> _securityEvents = [];
  final List<String> _validatorEvents = [];
  final List<String> _timeline = [];
  final List<PipelineEvent> _events = [];
  final Map<String, int> _diversityBalance = {};
  final Map<String, int> _lineageBalance = {};
  double _averageConfidence = 0.0;
  int _processedCases = 0;

  PipelineAuditLogger({required this.traceId}) : startedAt = DateTime.now();

  void log(PipelineEvent event) {
    _events.add(event);
    logTimeline('Stage: ${event.stage} | Action: ${event.action} | Before: ${event.beforeCount} | After: ${event.afterCount}');
  }

  void logTimeline(String event) {
    _timeline.add('[${DateTime.now().toIso8601String()}] $event');
  }

  void logRejected(RejectedCaseInfo info) {
    _rejectedCases.add(info);
    logTimeline('Rejected case "${info.title}" at ${info.stage}');
  }

  void logRepair({required String testCaseId, required String operation}) {
    _repairLog.add('$testCaseId -> $operation');
  }

  void logFallback(String reason) {
    _fallbackTriggers.add(reason);
    logTimeline('Fallback triggered: $reason');
  }

  void logSecurityEvent(String event) {
    _securityEvents.add(event);
  }

  void logValidatorEvent(String event) {
    _validatorEvents.add(event);
  }

  void recordCases(List<WorkingCase> cases) {
    _processedCases = cases.length;
    if (cases.isEmpty) {
      _averageConfidence = 0.0;
      return;
    }
    double totalConfidence = 0;
    _diversityBalance.clear();
    _lineageBalance.clear();
    for (final tc in cases) {
      totalConfidence += tc.metadata.confidenceScore;
      final profile = tc.metadata.semanticProfile;
      _diversityBalance[profile] = (_diversityBalance[profile] ?? 0) + 1;
      final origin = tc.metadata.origin;
      _lineageBalance[origin] = (_lineageBalance[origin] ?? 0) + 1;
    }
    _averageConfidence = totalConfidence / cases.length;
  }

  List<RejectedCaseInfo> get rejectedCases => _rejectedCases;
  List<String> get repairLog => _repairLog;
  Map<String, int> get diversityBalance => _diversityBalance;
  double get averageConfidence => _averageConfidence;
  List<String> get fallbackTriggers => _fallbackTriggers;
  int get totalInputCases => _processedCases;
  int get finalizedCases => _processedCases - _rejectedCases.length;
  int get repairedCases => _repairLog.length;
  int get rejectedCount => _rejectedCases.length;

  PipelineAuditReport buildReport({List<String>? missingIntentIds}) {
  return PipelineAuditReport(
    traceId: traceId,
    rejectedCases: rejectedCases,
    repairLog: repairLog,
    diversityBalance: diversityBalance,
    averageConfidence: averageConfidence,
    fallbackTriggers: fallbackTriggers,
    totalInputCases: totalInputCases,
    finalizedCases: finalizedCases,
    repairedCases: repairedCases,
    rejectedCount: rejectedCount,
    missingIntentIds: missingIntentIds,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'traceId': traceId,
      'startedAt': startedAt.toIso8601String(),
      'processedCases': _processedCases,
      'averageConfidence': _averageConfidence,
      'rejectedCases': _rejectedCases.map((e) => {'title': e.title, 'reason': e.reason, 'stage': e.stage}).toList(),
      'repairLog': _repairLog,
      'fallbackTriggers': _fallbackTriggers,
      'securityEvents': _securityEvents,
      'validatorEvents': _validatorEvents,
      'diversityBalance': _diversityBalance,
      'lineageBalance': _lineageBalance,
      'timeline': _timeline,
      'events': _events.map((e) => e.toJson()).toList(),
    };
  }
}