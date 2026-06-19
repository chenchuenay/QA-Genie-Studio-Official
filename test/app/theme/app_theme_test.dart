import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';

void main() {
  group('AppTheme', () {
    test('darkTheme has dark brightness', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
    });

    test('darkTheme scaffold background is AppColors.background', () {
      expect(AppTheme.darkTheme.scaffoldBackgroundColor, AppColors.background);
    });

    test('darkTheme colorScheme primary is AppColors.accent', () {
      expect(AppTheme.darkTheme.colorScheme.primary, AppColors.accent);
    });

    test('darkTheme colorScheme error is AppColors.error', () {
      expect(AppTheme.darkTheme.colorScheme.error, AppColors.error);
    });

    test('darkTheme cardColor is AppColors.card', () {
      expect(AppTheme.darkTheme.cardColor, AppColors.card);
    });

    test('darkTheme dividerColor is AppColors.border', () {
      expect(AppTheme.darkTheme.dividerColor, AppColors.border);
    });

    test('darkTheme inputDecoration is filled', () {
      final inputTheme = AppTheme.darkTheme.inputDecorationTheme;
      expect(inputTheme.filled, true);
      expect(inputTheme.fillColor, AppColors.surface);
    });

    test('darkTheme inputDecoration has correct border radius', () {
      final inputTheme = AppTheme.darkTheme.inputDecorationTheme;
      final border = inputTheme.border as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(22));
    });

    test('darkTheme bottomNavBar has correct colors', () {
      final navTheme = AppTheme.darkTheme.bottomNavigationBarTheme;
      expect(navTheme.selectedItemColor, AppColors.accent);
      expect(navTheme.backgroundColor, const Color(0xFF07090D));
      expect(navTheme.type, BottomNavigationBarType.fixed);
    });
  });
}
