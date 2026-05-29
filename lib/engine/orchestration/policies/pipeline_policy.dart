import 'package:qa_genie/engine/models/generation_outcome.dart';

class PipelinePolicy {
  const PipelinePolicy();

  bool shouldRetry(
    GenerationOutcome outcome,
    int retryAttempt, {
    required bool canRetry,
    required String forensicReason,
    required String recoveryMode,
    required int requestedCaseCount,
    required String source,
  }) {
    if (retryAttempt >= 1) return false;
    return outcome.type == GenerationOutcomeType.transportFailure &&
        (outcome.statusCode == 429 || outcome.statusCode == 503);
  }

  bool shouldUseFullFallback(GenerationOutcome outcome) {
    return outcome.type == GenerationOutcomeType.emptyResponse ||
        outcome.type == GenerationOutcomeType.providerFailure ||
        outcome.type == GenerationOutcomeType.malformedResponse ||
        outcome.validCaseCount == 0;
  }

  bool shouldUsePartialExpansion(GenerationOutcome outcome) {
    return outcome.type == GenerationOutcomeType.partialSuccess &&
        outcome.validCaseCount > 0;
  }
}
