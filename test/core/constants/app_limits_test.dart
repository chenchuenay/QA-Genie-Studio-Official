import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/constants/app_limits.dart';

void main() {
  group('AppLimits', () {
    test('maxCasesPerSuite is 20', () {
      expect(AppLimits.maxCasesPerSuite, 20);
    });
  });
}
