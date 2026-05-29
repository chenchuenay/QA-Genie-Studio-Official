import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart'; // ✅ canonical

// lib/engine/models/pipeline_models.dart

/// ============================================================
/// CASE METADATA
/// ============================================================
///
/// Tracks forensic/debug information across pipeline stages.
/// Mutable intentionally for deterministic repair lifecycle.
///
class CaseMetadata {
  /// Original source of testcase.
  final CaseSource source;

  /// Repair events applied.
  final List<String> repairHistory;

  /// Validation failures/warnings.
  final List<String> validationIssues;

  /// Scoring penalties.
  final Map<String, double> qualityPenalties;

  /// Semantic profile classification.
  String semanticProfile;

  /// Diversity balancing signals.
  final Set<String> diversitySignals;

  /// Stable semantic fingerprint.
  String? fingerprint;

  /// Confidence after repairs/validation.
  double confidenceScore;

  /// Forensic logic: lineage labels (AI/FB/REP) are tracked internally
  /// but MUST NEVER be exposed to the user in UI or exports.
  String get origin => source.name;

  /// Pipeline traceability id.
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
}

/// ============================================================
/// WORKING CASE
/// ============================================================
///
/// Internal mutable testcase used during generation pipeline.
///
/// IMPORTANT:
/// - mutable intentionally
/// - NEVER export directly
/// - NEVER persist directly
///
// Inside pipeline_models.dart, replace the WorkingCase class with this:

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
  List<TestStep> steps; // now using canonical TestStep
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

  factory WorkingCase.fromModel(TestCaseModel model) {
    final categoryLock = model.type.isNotEmpty ? model.type : 'Positive';
    return WorkingCase(
      id: model.id,
      title: model.title,
      module: model.module,
      feature: model.feature,
      platform: model.platform,
      priority: model.priority,
      type: model.type,
      categoryLock: categoryLock,
      constraints: null,
      preconditions: List<String>.from(model.preconditions),
      testData: '',
      steps: model.steps
          .map(
            (s) =>
                TestStep(action: s.action, data: s.data, expected: s.expected),
          )
          .toList(),
      expectedResult: model.expectedResult,
      actualResult: model.actualResult,
      status: model.status,
      metadata: CaseMetadata(
        source: model.source,
        traceId: '',
        confidenceScore: 1.0,
        repairHistory: List.from(model.repairOperations),
        validationIssues: List.from(model.realismOperations),
      ),
    );
  }

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
      steps: steps
          .map(
            (s) =>
                TestStep(action: s.action, data: s.data, expected: s.expected),
          )
          .toList(),
      expectedResult: expectedResult,
      actualResult: actualResult,
      status: status,
      metadata: metadata.copy(),
    );
  }

  TestCaseModel toLegacyModel() {
    final model = TestCaseModel(
      source: metadata.source,
      id: id,
      title: title,
      module: module,
      feature: feature,
      platform: platform,
      priority: priority,
      type: type,
      preconditions: preconditions,
      steps: steps,
      expectedResult: expectedResult,
      actualResult: actualResult,
      status: status,
    );
    model.repairOperations = List.from(metadata.repairHistory);
    model.realismOperations = List.from(metadata.validationIssues);
    return model;
  }

  bool get isNegative => type.toLowerCase() == 'negative';
  bool get hasConstraints =>
      constraints != null && constraints!.trim().isNotEmpty;

  factory WorkingCase.fromJson(
    Map<String, dynamic> json, {
    String traceId = '',
  }) {
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
      steps: (json['steps'] as List? ?? [])
          .map((e) => TestStep.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
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
// GENERATION SESSION (uses canonical FinalizedTestCase)
// ============================================================

/// Singleton owner of the canonical workflow state.
///
/// Master Source Role:
/// UI components hold a reference to this session.
/// Edits to the testCases list within this session auto-sync across
/// all consumers (Table -> Summary -> Export).
///
class GenerationSession {
  final String traceId;

  final List<FinalizedTestCase> testCases; // ✅ uses canonical type

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

/// ============================================================
/// PIPELINE AUDIT REPORT
/// ============================================================
///
/// Full forensic report for debugging.
///
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

  // ===== INSIDE `PipelineAuditReport` class =====

  // ------------------------------------------------------------------
  // FORENSIC LOGGING FIELDS (added for headless tests)
  // All are nullable and default to null – no impact on production.
  // ------------------------------------------------------------------
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

  // ------------------------------------------------------------------
  // Modify the constructor to include these as optional named parameters
  // with default `null`.
  // ------------------------------------------------------------------
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
    // NEW PARAMETERS (all optional, default null)
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

  bool get hasFailures {
    return rejectedCases.isNotEmpty;
  }
}

/// ============================================================
/// REJECTED CASE INFO
/// ============================================================

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

/// ============================================================
/// GENERATION REQUEST
/// ============================================================

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
