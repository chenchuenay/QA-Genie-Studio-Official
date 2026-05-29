export 'app_colors.dart';
export 'app_text.dart';
export 'app_radius.dart';
export 'app_spacing.dart';

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text.dart';
import 'app_radius.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    scaffoldBackgroundColor: AppColors.background,

    splashColor: Colors.transparent,

    highlightColor: Colors.transparent,

    hoverColor: Colors.transparent,

    dividerColor: AppColors.border,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppColors.accent,
      unselectedItemColor: Color(0xFF8D93A3),
      showUnselectedLabels: true,
      backgroundColor: Color(0xFF07090D),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    cardColor: AppColors.card,

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.border),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.border),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
      ),

      hintStyle: AppText.hint,

      labelStyle: AppText.label,
    ),
  );
}
