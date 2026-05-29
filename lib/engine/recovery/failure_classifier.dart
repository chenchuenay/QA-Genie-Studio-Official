import 'dart:io';
import 'dart:async'; // for TimeoutException
import 'package:qa_genie/engine/models/generation_outcome.dart';

class FailureClassifier {
  const FailureClassifier();

  GenerationOutcome classify({
    required String rawResponse,
    required int requestedCaseCount,
    int? statusCode,
    Object? error,
    int extractedCaseCount = 0,
  }) {
    if (_isTransportFailure(statusCode, error)) {
      return _buildTransportFailure(
        statusCode: statusCode,
        error: error,
        requestedCaseCount: requestedCaseCount,
      );
    }

    if (rawResponse.trim().isEmpty) {
      return GenerationOutcome.emptyResponse(
        reason: 'AI returned empty response body.',
        requestedCaseCount: requestedCaseCount,
        rawResponse: rawResponse,
      );
    }

    if (extractedCaseCount == requestedCaseCount) {
      return GenerationOutcome.fullSuccess(
        rawResponse: rawResponse,
        validCaseCount: extractedCaseCount,
        requestedCaseCount: requestedCaseCount,
      );
    }

    if (extractedCaseCount > 0 && extractedCaseCount < requestedCaseCount) {
      return GenerationOutcome.partialSuccess(
        rawResponse: rawResponse,
        validCaseCount: extractedCaseCount,
        requestedCaseCount: requestedCaseCount,
        reason:
            'AI returned partial valid suite. Missing ${requestedCaseCount - extractedCaseCount} cases.',
      );
    }

    return GenerationOutcome.emptyResponse(
      reason: 'AI response unusable after parsing.',
      requestedCaseCount: requestedCaseCount,
      rawResponse: rawResponse,
    );
  }

  bool _isTransportFailure(int? statusCode, Object? error) {
    if (statusCode == 429 || statusCode == 503) return true;
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException)
      return true;
    return false;
  }

  GenerationOutcome _buildTransportFailure({
    required int requestedCaseCount,
    int? statusCode,
    Object? error,
  }) {
    if (statusCode == 429) {
      return GenerationOutcome.transportFailure(
        failureType: TransportFailureType.quota429,
        reason: 'AI quota exceeded (429).',
        requestedCaseCount: requestedCaseCount,
        statusCode: statusCode,
      );
    }
    if (statusCode == 503) {
      return GenerationOutcome.transportFailure(
        failureType: TransportFailureType.service503,
        reason: 'AI service unavailable (503).',
        requestedCaseCount: requestedCaseCount,
        statusCode: statusCode,
      );
    }
    if (error is TimeoutException) {
      return GenerationOutcome.transportFailure(
        failureType: TransportFailureType.timeout,
        reason: 'AI request timeout.',
        requestedCaseCount: requestedCaseCount,
      );
    }
    if (error is SocketException) {
      return GenerationOutcome.transportFailure(
        failureType: TransportFailureType.socket,
        reason: 'Socket/network failure.',
        requestedCaseCount: requestedCaseCount,
      );
    }
    return GenerationOutcome.transportFailure(
      failureType: TransportFailureType.unknown,
      reason: 'Unknown AI transport failure.',
      requestedCaseCount: requestedCaseCount,
      statusCode: statusCode,
    );
  }
}
