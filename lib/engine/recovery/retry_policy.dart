import 'package:qa_genie/engine/models/generation_outcome.dart';

class RetryPolicy {
  const RetryPolicy();

  bool shouldRetry({
    required GenerationOutcome outcome,
    required int currentAttempt,
  }) {
    if (!outcome.canRetry) {
      return false;
    }

    if (currentAttempt >= 1) {
      return false;
    }

    switch (outcome.transportFailureType) {
      case TransportFailureType.quota429:
      case TransportFailureType.service503:
      case TransportFailureType.timeout:
      case TransportFailureType.socket:
        return true;

      case TransportFailureType.unknown:
      case null:
        return false;
    }
  }
}
