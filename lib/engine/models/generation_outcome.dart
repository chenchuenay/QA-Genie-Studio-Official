enum GenerationOutcomeType {
  fullSuccess,
  partialSuccess,
  malformedResponse,
  emptyResponse,
  transportFailure,
  providerFailure,
  fallbackRecovered,
}

enum TransportFailureType { timeout, quota429, service503, socket, unknown }

enum RecoveryMode {
  none,
  retry,
  partialExpansion,
  fullDeterministicFallback,
  malformedJsonRecovery,
}

class GenerationOutcome {
  final GenerationOutcomeType type;
  final String rawResponse;
  final int validCaseCount;
  final int requestedCaseCount;
  final bool canRetry;
  final TransportFailureType? transportFailureType;
  final RecoveryMode recoveryMode;
  final String forensicReason;
  final int? statusCode;

  const GenerationOutcome({
    required this.type,
    required this.rawResponse,
    required this.validCaseCount,
    required this.requestedCaseCount,
    required this.canRetry,
    required this.recoveryMode,
    required this.forensicReason,
    this.transportFailureType,
    this.statusCode,
  });

  bool get isFullSuccess => type == GenerationOutcomeType.fullSuccess;
  bool get isPartialSuccess => type == GenerationOutcomeType.partialSuccess;
  bool get requiresFallback =>
      type == GenerationOutcomeType.emptyResponse ||
      type == GenerationOutcomeType.transportFailure ||
      type == GenerationOutcomeType.providerFailure ||
      type == GenerationOutcomeType.malformedResponse;

  int get missingCaseCount {
    final missing = requestedCaseCount - validCaseCount;
    return missing < 0 ? 0 : missing;
  }

  factory GenerationOutcome.fullSuccess({
    required String rawResponse,
    required int validCaseCount,
    required int requestedCaseCount,
  }) {
    return GenerationOutcome(
      type: GenerationOutcomeType.fullSuccess,
      rawResponse: rawResponse,
      validCaseCount: validCaseCount,
      requestedCaseCount: requestedCaseCount,
      canRetry: false,
      recoveryMode: RecoveryMode.none,
      forensicReason: 'Complete valid suite from AI.',
    );
  }

  factory GenerationOutcome.partialSuccess({
    required String rawResponse,
    required int validCaseCount,
    required int requestedCaseCount,
    required String reason,
  }) {
    return GenerationOutcome(
      type: GenerationOutcomeType.partialSuccess,
      rawResponse: rawResponse,
      validCaseCount: validCaseCount,
      requestedCaseCount: requestedCaseCount,
      canRetry: false,
      recoveryMode: RecoveryMode.partialExpansion,
      forensicReason: reason,
    );
  }

  factory GenerationOutcome.transportFailure({
    required TransportFailureType failureType,
    required String reason,
    required int requestedCaseCount,
    int? statusCode,
  }) {
    return GenerationOutcome(
      type: GenerationOutcomeType.transportFailure,
      rawResponse: '',
      validCaseCount: 0,
      requestedCaseCount: requestedCaseCount,
      canRetry: true,
      transportFailureType: failureType,
      recoveryMode: RecoveryMode.retry,
      forensicReason: reason,
      statusCode: statusCode,
    );
  }

  factory GenerationOutcome.providerFailure({
    required String reason,
    required int requestedCaseCount,
    int? statusCode,
  }) {
    return GenerationOutcome(
      type: GenerationOutcomeType.providerFailure,
      rawResponse: '',
      validCaseCount: 0,
      requestedCaseCount: requestedCaseCount,
      canRetry: false,
      recoveryMode: RecoveryMode.fullDeterministicFallback,
      forensicReason: reason,
      statusCode: statusCode,
    );
  }

  factory GenerationOutcome.emptyResponse({
    required String reason,
    required int requestedCaseCount,
    required String rawResponse,
  }) {
    return GenerationOutcome(
      type: GenerationOutcomeType.emptyResponse,
      rawResponse: rawResponse,
      validCaseCount: 0,
      requestedCaseCount: requestedCaseCount,
      canRetry: false,
      recoveryMode: RecoveryMode.fullDeterministicFallback,
      forensicReason: reason,
    );
  }
}
