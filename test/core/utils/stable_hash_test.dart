import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/utils/stable_hash.dart';

void main() {
  group('StableHash.forText', () {
    test('returns 0 when max <= 1', () {
      expect(StableHash.forText('anything', 0), 0);
      expect(StableHash.forText('anything', 1), 0);
    });

    test('returns 0 for empty normalized string', () {
      expect(StableHash.forText('   ', 10), 0);
      expect(StableHash.forText('', 10), 0);
    });

    test('is deterministic — same input same result', () {
      final a = StableHash.forText('login flow', 100);
      final b = StableHash.forText('login flow', 100);
      expect(a, b);
    });

    test('returns value in [0, max)', () {
      for (int i = 0; i < 20; i++) {
        final result = StableHash.forText('test seed $i', 50);
        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThan(50));
      }
    });

    test('different inputs produce different indices (probabilistic)', () {
      final results = <int>{};
      for (int i = 0; i < 10; i++) {
        results.add(StableHash.forText('unique seed $i', 100));
      }
      expect(results.length, greaterThan(1));
    });
  });

  group('StableHash.fingerprint', () {
    test('returns EMPTY_HASH for empty text', () {
      expect(StableHash.fingerprint(''), 'EMPTY_HASH');
      expect(StableHash.fingerprint('   '), 'EMPTY_HASH');
    });

    test('is deterministic', () {
      expect(StableHash.fingerprint('hello world'), StableHash.fingerprint('hello world'));
    });

    test('returns 40-char hex string', () {
      final result = StableHash.fingerprint('some text');
      expect(result.length, 40);
      expect(result, matches(RegExp(r'^[a-f0-9]{40}$')));
    });

    test('normalizes input (trim, lowercase, collapse spaces)', () {
      expect(StableHash.fingerprint('Hello  World'), StableHash.fingerprint('hello world'));
    });
  });

  group('StableHash.compositeFingerprint', () {
    test('combines multiple fields into one hash', () {
      final result = StableHash.compositeFingerprint(
        title: 'Login test',
        module: 'Auth',
        feature: 'Login',
        expectedResult: 'Success',
      );
      expect(result.length, 40);
      expect(result, matches(RegExp(r'^[a-f0-9]{40}$')));
    });

    test('is deterministic for same inputs', () {
      final a = StableHash.compositeFingerprint(title: 'T', module: 'M', feature: 'F', expectedResult: 'E');
      final b = StableHash.compositeFingerprint(title: 'T', module: 'M', feature: 'F', expectedResult: 'E');
      expect(a, b);
    });

    test('different fields produce different hashes', () {
      final a = StableHash.compositeFingerprint(title: 'T1', module: 'M', feature: 'F', expectedResult: 'E');
      final b = StableHash.compositeFingerprint(title: 'T2', module: 'M', feature: 'F', expectedResult: 'E');
      expect(a, isNot(b));
    });
  });
}
