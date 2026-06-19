import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/enums/test_case_origin.dart';

void main() {
  group('TestCaseOrigin', () {
    test('all three values exist', () {
      expect(TestCaseOrigin.values.length, 3);
      expect(TestCaseOrigin.values, contains(TestCaseOrigin.ai));
      expect(TestCaseOrigin.values, contains(TestCaseOrigin.repairedAi));
      expect(TestCaseOrigin.values, contains(TestCaseOrigin.fallback));
    });
  });
}
