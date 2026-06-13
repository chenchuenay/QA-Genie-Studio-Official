import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

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
  final String intentId;

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
    this.intentId = '__unknown__',
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
      intentId: intentId,
    );
  }

  String get origin => source.name;
}

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
  final String intentId;

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
    this.intentId = '__unknown__',
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
      intentId: intentId,
    );
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
      categoryLock: json['categoryLock'] ?? json['category'] ?? 'positive',
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
      intentId: json['intent_id'] ?? json['intentId'] ?? '__unknown__',
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
    'intent_id': intentId,
  };
}

class QuotaExceededException implements Exception {
  final String message;
  final bool isRateLimit;
  QuotaExceededException(this.message, {this.isRateLimit = false});
  @override
  String toString() => 'QuotaExceededException: $message';
}

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

class RejectedCaseInfo {
  final String title;
  final String reason;
  final String stage;
  const RejectedCaseInfo({
    required this.title,
    required this.reason,
    required this.stage,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'reason': reason,
    'stage': stage,
  };
}

class GenerationRequest {
  final String module;
  final String feature;
  final String platform;
  final String generationMode;
  final int requestedCaseCount;
  final String constraints;
  final String domain;
  final List<Map<String, dynamic>> plan;
  final String traceId;
  final String? adToken; // optional for rewarded generations
  final String? deviceId;

  const GenerationRequest({
    required this.module,
    required this.feature,
    required this.platform,
    required this.generationMode,
    required this.requestedCaseCount,
    this.constraints = '',
    this.domain = 'general',
    this.plan = const [],
    required this.traceId,
    this.adToken,
    this.deviceId,
  });
}

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
  final List<String>? missingIntentIds;

  // Existing forensic fields
  final String? prompt;
  final String? rawAiResponse;
  final int? aiLatencyMs;
  final String? aiModel;
  final String? aiEndpoint;
  final int? aiStatusCode;
  final int? aiReturnedCount;
  final int? aiAcceptedCount;
  final int? structuralRejectedCount;
  final int? semanticRejectedCount;
  final int? realismRejectedCount;
  final int? exportSafetyRejectedCount;
  final int? repairedCount;
  final int? fallbackCount;

  // New cloud & AI detailed fields
  final String? cloudRequestId;
  final String? cloudFunctionVersion;
  final int? cloudLatencyMs;
  final int? aiPromptTokens;
  final int? aiCompletionTokens;
  final int? aiTotalTokens;
  final String? aiErrorCode;
  final String? aiErrorMessage;
  final String? aiModelName;
  final String? aiApiUrl;
  final int? aiHttpStatusCode;
  final Map<String, dynamic>? aiErrorDetails;
  final String? cloudFunctionName;
  final String? cloudFunctionRegion;
  final String? networkErrorType;
  final int? totalRetriesAttempted;
  final bool? wasResponseMalformed;
  final List<String> parserErrorMessages;

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
    this.missingIntentIds,
    this.prompt,
    this.rawAiResponse,
    this.aiLatencyMs,
    this.aiModel,
    this.aiEndpoint,
    this.aiStatusCode,
    this.aiReturnedCount,
    this.aiAcceptedCount,
    this.structuralRejectedCount,
    this.semanticRejectedCount,
    this.realismRejectedCount,
    this.exportSafetyRejectedCount,
    this.repairedCount,
    this.fallbackCount,
    this.cloudRequestId,
    this.cloudFunctionVersion,
    this.cloudLatencyMs,
    this.aiPromptTokens,
    this.aiCompletionTokens,
    this.aiTotalTokens,
    this.aiErrorCode,
    this.aiErrorMessage,
    this.aiModelName,
    this.aiApiUrl,
    this.aiHttpStatusCode,
    this.aiErrorDetails,
    this.cloudFunctionName,
    this.cloudFunctionRegion,
    this.networkErrorType,
    this.totalRetriesAttempted,
    this.wasResponseMalformed,
    this.parserErrorMessages = const [],
  });

  bool get hasFailures => rejectedCases.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'traceId': traceId,
      'rejectedCases': rejectedCases.map((e) => e.toJson()).toList(),
      'repairLog': repairLog,
      'diversityBalance': diversityBalance,
      'averageConfidence': averageConfidence,
      'fallbackTriggers': fallbackTriggers,
      'totalInputCases': totalInputCases,
      'finalizedCases': finalizedCases,
      'repairedCases': repairedCases,
      'rejectedCount': rejectedCount,
      'missingIntentIds': missingIntentIds,
      'prompt': _truncate(prompt),
      'rawAiResponse': _truncate(rawAiResponse, 5000),
      'aiLatencyMs': aiLatencyMs,
      'aiModel': aiModel,
      'aiEndpoint': aiEndpoint,
      'aiStatusCode': aiStatusCode,
      'aiReturnedCount': aiReturnedCount,
      'aiAcceptedCount': aiAcceptedCount,
      'structuralRejectedCount': structuralRejectedCount,
      'semanticRejectedCount': semanticRejectedCount,
      'realismRejectedCount': realismRejectedCount,
      'exportSafetyRejectedCount': exportSafetyRejectedCount,
      'repairedCount': repairedCount,
      'fallbackCount': fallbackCount,
      'cloudRequestId': cloudRequestId,
      'cloudFunctionVersion': cloudFunctionVersion,
      'cloudLatencyMs': cloudLatencyMs,
      'aiPromptTokens': aiPromptTokens,
      'aiCompletionTokens': aiCompletionTokens,
      'aiTotalTokens': aiTotalTokens,
      'aiErrorCode': aiErrorCode,
      'aiErrorMessage': aiErrorMessage,
      'aiModelName': aiModelName,
      'aiApiUrl': aiApiUrl,
      'aiHttpStatusCode': aiHttpStatusCode,
      'aiErrorDetails': aiErrorDetails,
      'cloudFunctionName': cloudFunctionName,
      'cloudFunctionRegion': cloudFunctionRegion,
      'networkErrorType': networkErrorType,
      'totalRetriesAttempted': totalRetriesAttempted,
      'wasResponseMalformed': wasResponseMalformed,
      'parserErrorMessages': parserErrorMessages,
    };
  }

  String? _truncate(String? value, [int max = 1000]) {
    if (value == null) return null;
    return value.length <= max
        ? value
        : '${value.substring(0, max)}...[truncated]';
  }
}
