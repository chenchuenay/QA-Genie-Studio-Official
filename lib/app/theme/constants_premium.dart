import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF05060A);
  static const surface = Color(0xFF0D1018);
  static const card = Color(0xFF141922);
  static const input = Color(0xFF12141C);
  static const modal = Color(0xFF0D1017);
  static const accent = Color(0xFF3DDCFF);
  static const accentLight = Color(0xFF7BE7FF);
  static const border = Color(0xFF232938);
  static const focusedBorder = Color(0xFF3DDCFF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFE5EAF3);
  static const textTertiary = Color(0xFFB8C0CF);
  static const textHint = Color(0xFF72798A);
  static const success = Color(0xFF2ED47A);
  static const error = Color(0xFFFF5C7A);
  static const warning = Color(0xFFFFB648);
  static const highPriority = Color(0xFFFF6B6B);
  static const mediumPriority = Color(0xFFFFC857);
  static const lowPriority = Color(0xFF4DD599);
  static const blue = Color(0xFF42A5F5);
  static const orange = Color(0xFFFFA726);
  static const purple = Color(0xFFAB47BC);
}

class AppSpacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32;
}

class AppRadius {
  static const double input = 22;
  static const double button = 22;
  static const double card = 24;
  static const double bottomSheet = 30;
  static const double dialog = 34;
  static const double chip = 18;
}

class AppText {
  static const TextStyle appTitle = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.2, color: Colors.white);
  static const TextStyle screenTitle = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.3, color: Colors.white);
  static const TextStyle section = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 3.5, height: 1.3, color: Color(0xFF67E8FF));
  static const TextStyle cardTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.3, color: Colors.white);
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5, color: Color(0xFFB8C0CF));
  static const TextStyle label = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: Color(0xFFA8B0C0));
  static const TextStyle input = TextStyle(fontSize: 17, fontWeight: FontWeight.w500, height: 1.4, color: Colors.white);
  static const TextStyle button = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: Colors.black);
  static const TextStyle chip = TextStyle(fontSize: 11, fontWeight: FontWeight.w700);
  static const TextStyle hint = TextStyle(fontSize: 13, color: Color(0xFF72798A));
}
