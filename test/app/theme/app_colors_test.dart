import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('background is dark', () {
      expect(AppColors.background, const Color(0xFF05060A));
    });

    test('surface is slightly lighter', () {
      expect(AppColors.surface, const Color(0xFF0D1018));
    });

    test('accent is cyan', () {
      expect(AppColors.accent, const Color(0xFF3DDCFF));
    });

    test('textPrimary is white', () {
      expect(AppColors.textPrimary, const Color(0xFFFFFFFF));
    });

    test('success is green', () {
      expect(AppColors.success, const Color(0xFF2ED47A));
    });

    test('error is red', () {
      expect(AppColors.error, const Color(0xFFFF5C7A));
    });

    test('warning is amber', () {
      expect(AppColors.warning, const Color(0xFFFFB648));
    });

    test('high priority is distinct', () {
      expect(AppColors.highPriority, const Color(0xFFFF6B6B));
    });

    test('medium priority is amber', () {
      expect(AppColors.mediumPriority, const Color(0xFFFFC857));
    });

    test('low priority is green', () {
      expect(AppColors.lowPriority, const Color(0xFF4DD599));
    });

    test('border is dark grey', () {
      expect(AppColors.border, const Color(0xFF232938));
    });

    test('surface color is correct', () {
      expect(AppColors.card, const Color(0xFF141922));
    });

    test('secondary text is light grey', () {
      expect(AppColors.textSecondary, const Color(0xFFE5EAF3));
    });
  });
}
