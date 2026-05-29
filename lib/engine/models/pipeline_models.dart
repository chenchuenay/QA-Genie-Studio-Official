import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

// ============================================================
// CASE METADATA
// ============================================================

class CaseMetadata {
  final CaseSource source;
  final List<String> repairHistory;
  final List<String> validationIssues;
  final Map<String, double> qualityPenalties;
  String semanticProfile;
  final Set<String> diversitySignals;
  String? fingerprint;
  double confidenceScore;
  final String traceId;

  CaseMetadata({
    required this.source,
    required this.traceId,
    this.repairHistory = const [],
    this.validationIssues = const [],
    this.qualityPenalties = const {},
    this.semanticProfile = 'unknown',
    this.diversitySignals = const {},
    this.fingerprint,
    this.confidenceScore = 1.0,
  });

  CaseMetadata copy() {
    return CaseMetadata(
      source: source,
      traceId: traceId,
      repairHistory: List.from(repairHistory),
      validationIssues: List.from(validationIssues),
      qualityPenalties: Map.from(qualityPenalties),
      semanticProfile: semanticProfile,
      diversitySignals: Set.from(diversitySignals),
      fingerprint: fingerprint,
      confidenceScore: confidenceScore,
    );
  }

  // ✅ Add this getter to satisfy pipeline_audit_logger.dart
  String get origin => source.name;
}

// ============================================================
// WORKING CASE (no legacy dependencies)
// ============================================================

class WorkingCase {
  String id;
  String title;
  String module;
  String feature;
  String platform;
  String priority;
  String type;
  String categoryLock;
  String? constraints;
  List<String> preconditions;
  String testData;
  List<TestStep> steps;
  String expectedResult;
  String actualResult;
  String status;
  final CaseMetadata metadata;

  WorkingCase({
    required this.id,
    required this.title,
    required this.module,
    required this.feature,
    required this.platform,
    required this.priority,
    required this.type,
    required this.categoryLock,
    this.constraints,
    required this.preconditions,
    required this.testData,
    required this.steps,
    required this.expectedResult,
    required this.actualResult,
    required this.status,
    required this.metadata,
  });

  WorkingCase copy() {
    return WorkingCase(
      id: id,
      title: title,
      module: module,
      feature: feature,
      platform: platform,
      priority: priority,
      type: type,
      categoryLock: categoryLock,
      constraints: constraints,
      preconditions: List.from(preconditions),
      testData: testData,
      steps: steps.map((s) => TestStep(action: s.action, data: s.data, expected: s.expected)).toList(),
      expectedResult: expectedResult,
      actualResult: actualResult,
      status: status,
      metadata: metadata.copy(),
    );
  }

  bool get isNegative => type.toLowerCase() == 'negative';
  bool get hasConstraints => constraints != null && constraints!.trim().isNotEmpty;

  factory WorkingCase.fromJson(Map<String, dynamic> json, {String traceId = ''}) {
    return WorkingCase(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      module: json['module'] ?? '',
      feature: json['feature'] ?? '',
      platform: json['platform'] ?? '',
      priority: json['priority'] ?? 'Medium',
      type: json['type'] ?? 'Positive',
      categoryLock: json['categoryLock'] ?? 'Positive',
      constraints: json['constraints'],
      preconditions: List<String>.from(json['preconditions'] ?? []),
      testData: json['testData'] ?? '',
      steps: (json['steps'] as List? ?? []).map((e) {
        final map = e as Map<String, dynamic>;
        return TestStep.fromJson(map);
      }).toList(),
      expectedResult: json['expectedResult'] ?? '',
      actualResult: json['actualResult'] ?? '',
      status: json['status'] ?? 'Not Executed',
      metadata: CaseMetadata(source: CaseSource.ai, traceId: traceId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'module': module,
        'feature': feature,
        'platform': platform,
        'priority': priority,
        'type': type,
        'categoryLock': categoryLock,
        'constraints': constraints,
        'preconditions': preconditions,
        'testData': testData,
        'steps': steps.map((e) => e.toJson()).toList(),
        'expectedResult': expectedResult,
        'actualResult': actualResult,
        'status': status,
      };
}

// ============================================================
// GENERATION SESSION (mutable testCases)
// ============================================================

class GenerationSession {
  final String traceId;
  List<FinalizedTestCase> testCases;
  final PipelineAuditReport auditReport;
  final int createdAt;

  GenerationSession({
    required this.traceId,
    required this.testCases,
    required this.auditReport,
  }) : createdAt = DateTime.now().millisecondsSinceEpoch;

  bool get isEmpty => testCases.isEmpty;
  int get count => testCases.length;
}

// ============================================================
// PIPELINE AUDIT REPORT
// ============================================================

class PipelineAuditReport {
  final String traceId;
  final List<RejectedCaseInfo> rejectedCases;
  final List<String> repairLog;
  final Map<String, int> diversityBalance;
  final double averageConfidence;
  final List<String> fallbackTriggers;
  final int totalInputCases;
  final int finalizedCases;
  final int repairedCases;
  final int rejectedCount;

  // forensic logging fields (optional)
  final String? prompt;
  final String? rawAiResponse;
  final int? aiLatencyMs;
  final String? aiModel;
  final String? aiEndpoint;
  final int? aiStatusCode;
  final int? aiReturnedCount;
  final int? structuralRejectedCount;
  final int? semanticRejectedCount;
  final int? realismRejectedCount;
  final int? exportSafetyRejectedCount;
  final int? repairedCount;
  final int? fallbackCount;

  const PipelineAuditReport({
    required this.traceId,
    this.rejectedCases = const [],
    this.repairLog = const [],
    this.diversityBalance = const {},
    this.averageConfidence = 0.0,
    this.fallbackTriggers = const [],
    this.totalInputCases = 0,
    this.finalizedCases = 0,
    this.repairedCases = 0,
    this.rejectedCount = 0,
    this.prompt,
    this.rawAiResponse,
    this.aiLatencyMs,
    this.aiModel,
    this.aiEndpoint,
    this.aiStatusCode,
    this.aiReturnedCount,
    this.structuralRejectedCount,
    this.semanticRejectedCount,
    this.realismRejectedCount,
    this.exportSafetyRejectedCount,
    this.repairedCount,
    this.fallbackCount,
  });

  factory PipelineAuditReport.failure({
    required String reason,
    String stackTrace = '',
    String traceId = 'UNKNOWN_TRACE',
  }) {
    return PipelineAuditReport(
      traceId: traceId,
      rejectedCases: [
        RejectedCaseInfo(
          title: 'Pipeline failure',
          reason: stackTrace.isEmpty ? reason : '$reason\n$stackTrace',
          stage: 'pipeline',
        ),
      ],
      rejectedCount: 1,
      fallbackTriggers: const ['pipeline_failure'],
    );
  }

  bool get hasFailures => rejectedCases.isNotEmpty;
}

// ============================================================
// REJECTED CASE INFO
// ============================================================

class RejectedCaseInfo {
  final String title;
  final String reason;
  final String stage;
  const RejectedCaseInfo({
    required this.title,
    required this.reason,
    required this.stage,
  });
}

// ============================================================
// GENERATION REQUEST
// ============================================================

class GenerationRequest {
  final String module;
  final String feature;
  final String platform;
  final String generationMode;
  final int requestedCaseCount;
  final String constraints;
  final String domain;

  const GenerationRequest({
    required this.module,
    required this.feature,
    required this.platform,
    required this.generationMode,
    required this.requestedCaseCount,
    this.constraints = '',
    this.domain = 'general',
  });
}