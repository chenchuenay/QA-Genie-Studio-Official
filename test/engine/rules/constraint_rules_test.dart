import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/rules/constraint_rules.dart';

void main() {
  group('ConstraintRules', () {
    test('can be instantiated', () {
      final rules = ConstraintRules();
      expect(rules, isNotNull);
    });
  });
}
