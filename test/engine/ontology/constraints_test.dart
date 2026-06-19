import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/ontology/constraints.dart';

void main() {
  group('ConstraintIntent', () {
    test('has all expected enum values', () {
      expect(ConstraintIntent.values, contains(ConstraintIntent.security));
      expect(ConstraintIntent.values, contains(ConstraintIntent.validation));
      expect(ConstraintIntent.values, contains(ConstraintIntent.boundary));
      expect(ConstraintIntent.values, contains(ConstraintIntent.positiveOnly));
      expect(ConstraintIntent.values, contains(ConstraintIntent.negativeOnly));
      expect(ConstraintIntent.values, contains(ConstraintIntent.positiveAndNegative));
      expect(ConstraintIntent.values, contains(ConstraintIntent.sessionOnly));
      expect(ConstraintIntent.values, contains(ConstraintIntent.oauthOnly));
      expect(ConstraintIntent.values, contains(ConstraintIntent.none));
    });
  });

  group('ConstraintParserResult', () {
    test('can be created with intent and keywords', () {
      final result = ConstraintParserResult(
        intent: ConstraintIntent.security,
        keywords: {'token', 'expired'},
      );
      expect(result.intent, ConstraintIntent.security);
      expect(result.keywords, {'token', 'expired'});
    });

    test('can be created with empty keywords', () {
      final result = ConstraintParserResult(
        intent: ConstraintIntent.none,
        keywords: {},
      );
      expect(result.intent, ConstraintIntent.none);
      expect(result.keywords, isEmpty);
    });
  });

  group('ConstraintUtils.detectIntent', () {
    test('detects security intent', () {
      expect(ConstraintUtils.detectIntent('security'), ConstraintIntent.security);
      expect(ConstraintUtils.detectIntent('only security'), ConstraintIntent.security);
      expect(ConstraintUtils.detectIntent('security only'), ConstraintIntent.security);
    });

    test('does not detect security when positive is present', () {
      expect(ConstraintUtils.detectIntent('security positive'), isNot(ConstraintIntent.security));
    });

    test('detects validation intent', () {
      expect(ConstraintUtils.detectIntent('only validation'), ConstraintIntent.validation);
      expect(ConstraintUtils.detectIntent('validation only'), ConstraintIntent.validation);
    });

    test('detects boundary intent', () {
      expect(ConstraintUtils.detectIntent('only boundary'), ConstraintIntent.boundary);
      expect(ConstraintUtils.detectIntent('boundary only'), ConstraintIntent.boundary);
    });

    test('detects positiveOnly intent', () {
      expect(ConstraintUtils.detectIntent('only positive'), ConstraintIntent.positiveOnly);
      expect(ConstraintUtils.detectIntent('positive only'), ConstraintIntent.positiveOnly);
    });

    test('detects negativeOnly intent', () {
      expect(ConstraintUtils.detectIntent('only negative'), ConstraintIntent.negativeOnly);
      expect(ConstraintUtils.detectIntent('negative only'), ConstraintIntent.negativeOnly);
    });

    test('detects positiveAndNegative intent', () {
      expect(ConstraintUtils.detectIntent('positive and negative'), ConstraintIntent.positiveAndNegative);
      expect(ConstraintUtils.detectIntent('include both positive and negative'), ConstraintIntent.positiveAndNegative);
    });

    test('detects sessionOnly intent', () {
      expect(ConstraintUtils.detectIntent('only session'), ConstraintIntent.sessionOnly);
      expect(ConstraintUtils.detectIntent('session only'), ConstraintIntent.sessionOnly);
      expect(ConstraintUtils.detectIntent('session'), ConstraintIntent.sessionOnly);
    });

    test('does not detect sessionOnly when expiry is present', () {
      expect(ConstraintUtils.detectIntent('session expiry'), isNot(ConstraintIntent.sessionOnly));
    });

    test('detects oauthOnly intent', () {
      expect(ConstraintUtils.detectIntent('oauth'), ConstraintIntent.oauthOnly);
      expect(ConstraintUtils.detectIntent('social login'), ConstraintIntent.oauthOnly);
    });

    test('returns none for unmatched input', () {
      expect(ConstraintUtils.detectIntent(''), ConstraintIntent.none);
      expect(ConstraintUtils.detectIntent('random text'), ConstraintIntent.none);
    });
  });

  group('ConstraintUtils.extractKeywords', () {
    test('extracts keywords from constraint string', () {
      final keywords = ConstraintUtils.extractKeywords('security token expired');
      expect(keywords, contains('security'));
      expect(keywords, contains('token'));
      expect(keywords, contains('expired'));
    });

    test('removes stop words', () {
      final keywords = ConstraintUtils.extractKeywords('only generate test cases for security');
      expect(keywords, isNot(contains('only')));
      expect(keywords, isNot(contains('generate')));
      expect(keywords, isNot(contains('test')));
      expect(keywords, isNot(contains('cases')));
      expect(keywords, isNot(contains('for')));
      expect(keywords, contains('security'));
    });

    test('filters out words shorter than 3 characters', () {
      final keywords = ConstraintUtils.extractKeywords('a an on it');
      expect(keywords, isEmpty);
    });

    test('strips non-word characters', () {
      final keywords = ConstraintUtils.extractKeywords('hello! world, test-case');
      expect(keywords, contains('hello'));
      expect(keywords, contains('world'));
      expect(keywords, contains('testcase'));
    });

    test('returns empty set for empty input', () {
      final keywords = ConstraintUtils.extractKeywords('');
      expect(keywords, isEmpty);
    });
  });
}
