import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/models/generation_outcome.dart';

void main() {
  group('GenerationOutcomeType', () {
    test('has all expected enum values', () {
      expect(GenerationOutcomeType.values, contains(GenerationOutcomeType.fullSuccess));
      expect(GenerationOutcomeType.values, contains(GenerationOutcomeType.partialSuccess));
      expect(GenerationOutcomeType.values, contains(GenerationOutcomeType.malformedResponse));
      expect(GenerationOutcomeType.values, contains(GenerationOutcomeType.emptyResponse));
      expect(GenerationOutcomeType.values, contains(GenerationOutcomeType.transportFailure));
      expect(GenerationOutcomeType.values, contains(GenerationOutcomeType.providerFailure));
      expect(GenerationOutcomeType.values, contains(GenerationOutcomeType.fallbackRecovered));
    });
  });

  group('TransportFailureType', () {
    test('has all expected enum values', () {
      expect(TransportFailureType.values, contains(TransportFailureType.timeout));
      expect(TransportFailureType.values, contains(TransportFailureType.quota429));
      expect(TransportFailureType.values, contains(TransportFailureType.service503));
      expect(TransportFailureType.values, contains(TransportFailureType.socket));
      expect(TransportFailureType.values, contains(TransportFailureType.unknown));
    });
  });

  group('RecoveryMode', () {
    test('has all expected enum values', () {
      expect(RecoveryMode.values, contains(RecoveryMode.none));
      expect(RecoveryMode.values, contains(RecoveryMode.retry));
      expect(RecoveryMode.values, contains(RecoveryMode.partialExpansion));
      expect(RecoveryMode.values, contains(RecoveryMode.fullDeterministicFallback));
      expect(RecoveryMode.values, contains(RecoveryMode.malformedJsonRecovery));
    });
  });

  group('GenerationOutcome.fullSuccess', () {
    test('creates a full success outcome', () {
      final outcome = GenerationOutcome.fullSuccess(
        rawResponse: '{"cases": []}',
        validCaseCount: 5,
        requestedCaseCount: 5,
      );
      expect(outcome.type, GenerationOutcomeType.fullSuccess);
      expect(outcome.rawResponse, '{"cases": []}');
      expect(outcome.validCaseCount, 5);
      expect(outcome.requestedCaseCount, 5);
      expect(outcome.canRetry, isFalse);
      expect(outcome.recoveryMode, RecoveryMode.none);
      expect(outcome.isFullSuccess, isTrue);
      expect(outcome.isPartialSuccess, isFalse);
      expect(outcome.requiresFallback, isFalse);
    });
  });

  group('GenerationOutcome.partialSuccess', () {
    test('creates a partial success outcome', () {
      final outcome = GenerationOutcome.partialSuccess(
        rawResponse: '{"cases": []}',
        validCaseCount: 3,
        requestedCaseCount: 5,
        reason: 'Some cases malformed',
      );
      expect(outcome.type, GenerationOutcomeType.partialSuccess);
      expect(outcome.validCaseCount, 3);
      expect(outcome.requestedCaseCount, 5);
      expect(outcome.canRetry, isFalse);
      expect(outcome.recoveryMode, RecoveryMode.partialExpansion);
      expect(outcome.forensicReason, 'Some cases malformed');
      expect(outcome.isPartialSuccess, isTrue);
      expect(outcome.requiresFallback, isFalse);
    });
  });

  group('GenerationOutcome.transportFailure', () {
    test('creates a transport failure outcome', () {
      final outcome = GenerationOutcome.transportFailure(
        failureType: TransportFailureType.timeout,
        reason: 'Connection timed out',
        requestedCaseCount: 5,
        statusCode: 504,
      );
      expect(outcome.type, GenerationOutcomeType.transportFailure);
      expect(outcome.rawResponse, '');
      expect(outcome.validCaseCount, 0);
      expect(outcome.canRetry, isTrue);
      expect(outcome.transportFailureType, TransportFailureType.timeout);
      expect(outcome.recoveryMode, RecoveryMode.retry);
      expect(outcome.statusCode, 504);
      expect(outcome.requiresFallback, isTrue);
    });

    test('creates a transport failure without statusCode', () {
      final outcome = GenerationOutcome.transportFailure(
        failureType: TransportFailureType.socket,
        reason: 'Socket error',
        requestedCaseCount: 3,
      );
      expect(outcome.transportFailureType, TransportFailureType.socket);
      expect(outcome.statusCode, isNull);
    });
  });

  group('GenerationOutcome.providerFailure', () {
    test('creates a provider failure outcome', () {
      final outcome = GenerationOutcome.providerFailure(
        reason: 'Provider unavailable',
        requestedCaseCount: 5,
        statusCode: 503,
      );
      expect(outcome.type, GenerationOutcomeType.providerFailure);
      expect(outcome.rawResponse, '');
      expect(outcome.validCaseCount, 0);
      expect(outcome.canRetry, isFalse);
      expect(outcome.recoveryMode, RecoveryMode.fullDeterministicFallback);
      expect(outcome.statusCode, 503);
      expect(outcome.requiresFallback, isTrue);
    });
  });

  group('GenerationOutcome.emptyResponse', () {
    test('creates an empty response outcome', () {
      final outcome = GenerationOutcome.emptyResponse(
        reason: 'Empty response from AI',
        requestedCaseCount: 5,
        rawResponse: '',
      );
      expect(outcome.type, GenerationOutcomeType.emptyResponse);
      expect(outcome.rawResponse, '');
      expect(outcome.validCaseCount, 0);
      expect(outcome.canRetry, isFalse);
      expect(outcome.recoveryMode, RecoveryMode.fullDeterministicFallback);
      expect(outcome.forensicReason, 'Empty response from AI');
      expect(outcome.requiresFallback, isTrue);
    });
  });

  group('GenerationOutcome.missingCaseCount', () {
    test('returns 0 when valid equals requested', () {
      final outcome = GenerationOutcome.fullSuccess(
        rawResponse: '',
        validCaseCount: 5,
        requestedCaseCount: 5,
      );
      expect(outcome.missingCaseCount, 0);
    });

    test('returns difference when valid is less than requested', () {
      final outcome = GenerationOutcome.partialSuccess(
        rawResponse: '',
        validCaseCount: 3,
        requestedCaseCount: 5,
        reason: '',
      );
      expect(outcome.missingCaseCount, 2);
    });

    test('returns 0 when valid exceeds requested', () {
      final outcome = GenerationOutcome.fullSuccess(
        rawResponse: '',
        validCaseCount: 7,
        requestedCaseCount: 5,
      );
      expect(outcome.missingCaseCount, 0);
    });
  });
}
