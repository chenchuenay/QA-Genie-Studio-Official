import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/parsers/response_classifier.dart';
import 'package:qa_genie/engine/models/generation_outcome.dart';

void main() {
  group('ResponseClassifier', () {
    late ResponseClassifier classifier;

    setUp(() {
      classifier = const ResponseClassifier();
    });

    test('classifies transport failure when transportFailure is true', () {
      final result = classifier.classify(
        rawResponse: 'some response',
        validCaseCount: 5,
        targetCaseCount: 5,
        malformed: false,
        transportFailure: true,
        statusCode: null,
      );
      expect(result, GenerationOutcomeType.transportFailure);
    });

    test('classifies transport failure for status 429', () {
      final result = classifier.classify(
        rawResponse: 'rate limited',
        validCaseCount: 0,
        targetCaseCount: 5,
        malformed: false,
        transportFailure: false,
        statusCode: 429,
      );
      expect(result, GenerationOutcomeType.transportFailure);
    });

    test('classifies transport failure for status 503', () {
      final result = classifier.classify(
        rawResponse: 'service unavailable',
        validCaseCount: 0,
        targetCaseCount: 5,
        malformed: false,
        transportFailure: false,
        statusCode: 503,
      );
      expect(result, GenerationOutcomeType.transportFailure);
    });

    test('classifies empty response for empty raw', () {
      final result = classifier.classify(
        rawResponse: '',
        validCaseCount: 0,
        targetCaseCount: 5,
        malformed: false,
        transportFailure: false,
        statusCode: null,
      );
      expect(result, GenerationOutcomeType.emptyResponse);
    });

    test('classifies empty response for whitespace-only raw', () {
      final result = classifier.classify(
        rawResponse: '   ',
        validCaseCount: 0,
        targetCaseCount: 5,
        malformed: false,
        transportFailure: false,
        statusCode: null,
      );
      expect(result, GenerationOutcomeType.emptyResponse);
    });

    test('classifies malformed when malformed and zero valid', () {
      final result = classifier.classify(
        rawResponse: '{broken}',
        validCaseCount: 0,
        targetCaseCount: 5,
        malformed: true,
        transportFailure: false,
        statusCode: null,
      );
      expect(result, GenerationOutcomeType.malformedResponse);
    });

    test('classifies empty when zero valid but not malformed', () {
      final result = classifier.classify(
        rawResponse: '{"testCases": []}',
        validCaseCount: 0,
        targetCaseCount: 5,
        malformed: false,
        transportFailure: false,
        statusCode: null,
      );
      expect(result, GenerationOutcomeType.emptyResponse);
    });

    test('classifies partial success when valid < target', () {
      final result = classifier.classify(
        rawResponse: '[{"title": "T1", "steps": []}]',
        validCaseCount: 3,
        targetCaseCount: 5,
        malformed: false,
        transportFailure: false,
        statusCode: null,
      );
      expect(result, GenerationOutcomeType.partialSuccess);
    });

    test('classifies full success when valid >= target', () {
      final result = classifier.classify(
        rawResponse: '[{"title": "T1", "steps": []}]',
        validCaseCount: 5,
        targetCaseCount: 5,
        malformed: false,
        transportFailure: false,
        statusCode: null,
      );
      expect(result, GenerationOutcomeType.fullSuccess);
    });
  });
}
