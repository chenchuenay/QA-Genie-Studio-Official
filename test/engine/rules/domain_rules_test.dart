import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/rules/domain_rules.dart';

void main() {
  group('DomainRules', () {
    test('can be instantiated', () {
      final rules = DomainRules();
      expect(rules, isNotNull);
    });
  });
}
