import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/planners/constraint_parser.dart';
import 'package:qa_genie/engine/ontology/constraints.dart';

void main() {
  group('ConstraintParser', () {
    group('parse', () {
      test('parses security-only constraint', () {
        final parser = ConstraintParser('only security');
        final result = parser.parse();
        expect(result.intent, ConstraintIntent.security);
      });

      test('parses validation-only constraint', () {
        final parser = ConstraintParser('only validation');
        final result = parser.parse();
        expect(result.intent, ConstraintIntent.validation);
      });

      test('parses boundary-only constraint', () {
        final parser = ConstraintParser('only boundary');
        final result = parser.parse();
        expect(result.intent, ConstraintIntent.boundary);
      });

      test('parses positive-only constraint', () {
        final parser = ConstraintParser('only positive');
        final result = parser.parse();
        expect(result.intent, ConstraintIntent.positiveOnly);
      });

      test('parses negative-only constraint', () {
        final parser = ConstraintParser('only negative');
        final result = parser.parse();
        expect(result.intent, ConstraintIntent.negativeOnly);
      });

      test('parses positive-and-negative constraint', () {
        final parser = ConstraintParser('positive and negative');
        final result = parser.parse();
        expect(result.intent, ConstraintIntent.positiveAndNegative);
      });

      test('parses session-only constraint', () {
        final parser = ConstraintParser('only session');
        final result = parser.parse();
        expect(result.intent, ConstraintIntent.sessionOnly);
      });

      test('parses oauth constraint', () {
        final parser = ConstraintParser('oauth');
        final result = parser.parse();
        expect(result.intent, ConstraintIntent.oauthOnly);
      });

      test('parses social login constraint', () {
        final parser = ConstraintParser('social login');
        final result = parser.parse();
        expect(result.intent, ConstraintIntent.oauthOnly);
      });

      test('parses empty constraint as none', () {
        final parser = ConstraintParser('');
        final result = parser.parse();
        expect(result.intent, ConstraintIntent.none);
      });

      test('parses gibberish constraint as none', () {
        final parser = ConstraintParser('some random text without keywords');
        final result = parser.parse();
        expect(result.intent, ConstraintIntent.none);
      });

      test('extracts keywords from constraint string', () {
        final parser = ConstraintParser('test insurance expired token');
        final result = parser.parse();
        expect(result.keywords, contains('insurance'));
        expect(result.keywords, contains('expired'));
        expect(result.keywords, contains('token'));
      });

      test('excludes stop words from keywords', () {
        final parser = ConstraintParser('only focus on generate');
        final result = parser.parse();
        expect(result.keywords, isEmpty);
      });

      test('handles mixed case constraint', () {
        final parser = ConstraintParser('ONLY SECURITY');
        final result = parser.parse();
        expect(result.intent, ConstraintIntent.security);
      });
    });

    group('ConstraintUtils.detectIntent', () {
      test('detects security intent with "security only"', () {
        expect(ConstraintUtils.detectIntent('security only'), ConstraintIntent.security);
      });

      test('detects security intent when security alone', () {
        expect(ConstraintUtils.detectIntent('security'), ConstraintIntent.security);
      });

      test('does not detect security when security with positive is not negative', () {
        expect(ConstraintUtils.detectIntent('security and positive'), ConstraintIntent.none);
      });

      test('detects session only from "session only"', () {
        expect(ConstraintUtils.detectIntent('session only'), ConstraintIntent.sessionOnly);
      });

      test('detects session only from standalone session', () {
        expect(ConstraintUtils.detectIntent('session'), ConstraintIntent.sessionOnly);
      });

      test('detects session only with session alone (no expiry)', () {
        expect(ConstraintUtils.detectIntent('session'), ConstraintIntent.sessionOnly);
      });
    });

    group('ConstraintUtils.extractKeywords', () {
      test('extracts meaningful keywords excluding stop words', () {
        final keywords = ConstraintUtils.extractKeywords('custom expired token insurance');
        expect(keywords, contains('custom'));
        expect(keywords, contains('expired'));
        expect(keywords, contains('token'));
        expect(keywords, contains('insurance'));
      });

      test('filters stop words', () {
        final keywords = ConstraintUtils.extractKeywords('only for custom');
        expect(keywords, contains('custom'));
        expect(keywords, isNot(contains('only')));
        expect(keywords, isNot(contains('for')));
      });

      test('filters short words (length <= 2)', () {
        final keywords = ConstraintUtils.extractKeywords('a to is custom');
        expect(keywords, contains('custom'));
        expect(keywords.length, 1);
      });

      test('strips non-word characters', () {
        final keywords = ConstraintUtils.extractKeywords('custom!! expired??');
        expect(keywords, contains('custom'));
        expect(keywords, contains('expired'));
      });

      test('returns empty set for empty input', () {
        final keywords = ConstraintUtils.extractKeywords('');
        expect(keywords, isEmpty);
      });
    });
  });
}
