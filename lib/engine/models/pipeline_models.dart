import 'package:qa_genie/data/models/test_case_model.dart';

/// Traceability metadata for a single case throughout the pipeline.
class CaseMetadata {
  final String origin; // 'AI', 'Fallback', 'Emergency'
  final List<String> repairHistory;
  final List<String> validationIssues;
  final Map<String, double> qualityPenalties;
  String semanticProfile;
  final Set<String> diversitySignals;
  String? fingerprint;
  double confidenceScore;

  CaseMetadata({
    required this.origin,
    this.repairHistory = const [],
    this.validationIssues = const [],
    this.qualityPenalties = const {},
    this.semanticProfile = 'unknown',
    this.diversitySignals = const {},
    this.fingerprint,
    this.confidenceScore = 1.0,
  });

  CaseMetadata copy() => CaseMetadata(
    origin: origin,
    repairHistory: List.from(repairHistory),
    validationIssues: List.from(validationIssues),
    qualityPenalties: Map.from(qualityPenalties),
    semanticProfile: semanticProfile,
    diversitySignals: Set.from(diversitySignals),
    fingerprint: fingerprint,
    confidenceScore: confidenceScore,
  );
}

/// The internal mutable representation of a test case during the compilation process.
class WorkingCase {
  String id;
  String title;
  String module;
  String feature;
  String platform;
  String priority;
  String type;
  List<String> preconditions;
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
    required this.preconditions,
    required this.steps,
    required this.expectedResult,
    required this.actualResult,
    required this.status,
    required this.metadata,
  });

  WorkingCase copy() => WorkingCase(
    id: id,
    title: title,
    module: module,
    feature: feature,
    platform: platform,
    priority: priority,
    type: type,
    preconditions: List.from(preconditions),
    steps: steps.map((s) => TestStep(action: s.action, data: s.data, expected: s.expected)).toList(),
    expectedResult: expectedResult,
    actualResult: actualResult,
    status: status,
    metadata: metadata.copy(),
  );

  TestCaseModel toLegacyModel() => TestCaseModel(
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
}

/// The final immutable, export-safe test case.
class FinalizedTestCase {
  final String id;
  final String title;
  final String module;
  final String feature;
  final String platform;
  final String priority;
  final String type;
  final List<String> preconditions;
  final List<FinalizedTestStep> steps;
  final String expectedResult;
  final String actualResult;
  final String status;
  final String schemaVersion;
  final CaseMetadata metadata;

  const FinalizedTestCase({
    required this.id,
    required this.title,
    required this.module,
    required this.feature,
    required this.platform,
    required this.priority,
    required this.type,
    required this.preconditions,
    required this.steps,
    required this.expectedResult,
    required this.actualResult,
    required this.status,
    required this.schemaVersion,
    required this.metadata,
  });
}

class FinalizedTestStep {
  final String action;
  final String data;
  final String expected;

  const FinalizedTestStep({
    required this.action,
    required this.data,
    required this.expected,
  });
}

/// A forensic report of the entire compilation process.
class PipelineAuditReport {
  final List<RejectedCaseInfo> rejectedCases;
  final List<String> repairLog;
  final Map<String, int> diversityBalance;
  final double averageConfidence;
  final List<String> fallbackTriggers;

  PipelineAuditReport({
    this.rejectedCases = const [],
    this.repairLog = const [],
    this.diversityBalance = const {},
    this.averageConfidence = 0.0,
    this.fallbackTriggers = const [],
  });
}

class RejectedCaseInfo {
  final String title;
  final String reason;
  final String stage;

  RejectedCaseInfo({required this.title, required this.reason, required this.stage});
}
