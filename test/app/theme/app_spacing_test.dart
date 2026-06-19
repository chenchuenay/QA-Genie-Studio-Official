import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/app/theme/app_spacing.dart';

void main() {
  group('AppSpacing', () {
    test('xs is 4', () {
      expect(AppSpacing.xs, 4);
    });

    test('sm is 8', () {
      expect(AppSpacing.sm, 8);
    });

    test('md is 16', () {
      expect(AppSpacing.md, 16);
    });

    test('lg is 24', () {
      expect(AppSpacing.lg, 24);
    });

    test('xl is 32', () {
      expect(AppSpacing.xl, 32);
    });
  });
}
