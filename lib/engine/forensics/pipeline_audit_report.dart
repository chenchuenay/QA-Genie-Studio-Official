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
  final String? prompt;
  final String? rawAiResponse;
  final int? aiLatencyMs;
  final int? aiStatusCode;
  final int? aiReturnedCount;
  final int? aiAcceptedCount;
  final int? structuralRejectedCount;
  final int? semanticRejectedCount;
  final int? realismRejectedCount;
  final int? exportSafetyRejectedCount;
  final int? fallbackCount;
  final String? cloudRequestId;
  final String? cloudFunctionVersion;
  final int? cloudLatencyMs;
  final int? aiPromptTokens;
  final int? aiCompletionTokens;
  final int? aiTotalTokens;
  final String? aiErrorCode;
  final String? aiErrorMessage;

  // New live error fields (must exist)
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
    this.aiStatusCode,
    this.aiReturnedCount,
    this.aiAcceptedCount,
    this.structuralRejectedCount,
    this.semanticRejectedCount,
    this.realismRejectedCount,
    this.exportSafetyRejectedCount,
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
      'aiStatusCode': aiStatusCode,
      'aiReturnedCount': aiReturnedCount,
      'aiAcceptedCount': aiAcceptedCount,
      'structuralRejectedCount': structuralRejectedCount,
      'semanticRejectedCount': semanticRejectedCount,
      'realismRejectedCount': realismRejectedCount,
      'exportSafetyRejectedCount': exportSafetyRejectedCount,
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

  String? _truncate(String? s, [int max = 1000]) {
    if (s == null) return null;
    return s.length <= max ? s : '${s.substring(0, max)}...[truncated]';
  }
}

class RejectedCaseInfo {
  final String title;
  final String reason;
  final String stage;
  RejectedCaseInfo({
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
