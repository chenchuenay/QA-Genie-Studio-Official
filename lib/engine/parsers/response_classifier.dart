import 'package:qa_genie/engine/models/generation_outcome.dart';

class ResponseClassifier {
  const ResponseClassifier();

  GenerationOutcomeType classify({
    required String rawResponse,
    required int validCaseCount,
    required int targetCaseCount,
    required bool malformed,
    required bool transportFailure,
    required int? statusCode,
  }) {
    if (transportFailure) {
      return GenerationOutcomeType.transportFailure;
    }

    if (statusCode == 429 || statusCode == 503) {
      return GenerationOutcomeType.transportFailure;
    }

    if (rawResponse.trim().isEmpty) {
      return GenerationOutcomeType.emptyResponse;
    }

    if (malformed && validCaseCount == 0) {
      return GenerationOutcomeType.malformedResponse;
    }

    if (validCaseCount == 0) {
      return GenerationOutcomeType.emptyResponse;
    }

    if (validCaseCount < targetCaseCount) {
      return GenerationOutcomeType.partialSuccess;
    }

    return GenerationOutcomeType.fullSuccess;
  }
}
