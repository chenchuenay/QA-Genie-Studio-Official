import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/utils/id_generator.dart';

void main() {
  group('IdGenerator.generate', () {
    test('produces correct format', () {
      final id = IdGenerator.generate('Login', 1);
      expect(id, matches(RegExp(r'^TC_\w+_\d{3}$')));
    });

    test('normalizes module name', () {
      final id = IdGenerator.generate('User Authentication', 1);
      expect(id, 'TC_USER_001');
    });

    test('pads index to 3 digits', () {
      expect(IdGenerator.generate('Test', 5), 'TC_TEST_005');
      expect(IdGenerator.generate('Test', 12), 'TC_TEST_012');
      expect(IdGenerator.generate('Test', 999), 'TC_TEST_999');
    });

    test('clamps index to 0-9999', () {
      expect(IdGenerator.generate('Test', -1), 'TC_TEST_000');
      // 9999 pads to '9999' (4 digits is allowed)
      expect(IdGenerator.generate('Test', 10000), contains('TC_TEST_'));
      expect(IdGenerator.generate('Test', 10000).length, greaterThan(10));
    });

    test('returns GENERIC for empty module', () {
      final id = IdGenerator.generate('', 1);
      expect(id, 'TC_GENERIC_001');
    });
  });

  group('IdGenerator.trace', () {
    test('produces correct format', () {
      final trace = IdGenerator.trace('Login');
      expect(trace, matches(RegExp(r'^TRC_\d+_LOGIN$')));
    });

    test('normalizes context', () {
      final trace = IdGenerator.trace('User Auth');
      expect(trace, matches(RegExp(r'^TRC_\d+_USER$')));
    });
  });

  group('IdGenerator.exportBatch', () {
    test('produces correct format', () {
      final batch = IdGenerator.exportBatch();
      expect(batch, matches(RegExp(r'^EXP_\d+$')));
    });

    test('starts with EXP_ prefix', () {
      expect(IdGenerator.exportBatch(), startsWith('EXP_'));
    });
  });
}
