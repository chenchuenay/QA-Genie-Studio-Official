import 'package:flutter/material.dart';
class AppColors {
  static const background = Color(0xFF05060A);
  static const surface = Color(0xFF0B0E14);
  static const accent = Color(0xFF3DDCFF);
  static const accentLight = Color(0xFF7BE7FF);
  static const accentPressed = Color(0xFF1AB8E6);
  static const card = Color(0xFF12141C);
  static const border = Color(0xFF232938);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFE5EAF3);
  static const textHint = Color(0xFFA8B0C0);
  static const success = Color(0xFF2ED47A);
  static const warning = Color(0xFFFFB648);
  static const error = Color(0xFFFF5C7A);
  static const blue = Color(0xFF3DDCFF);
  static const orange = Color(0xFFFFB648);
  static const purple = Color(0xFFAB47BC);
}
class AppSpacing { static const double xs=4, sm=8, md=12, lg=20, xl=28; }
class AppRadius { static const double sm=8, md=12, lg=16, xl=20; }
class AppText {
  static const TextStyle button = TextStyle(fontSize:18, fontWeight:FontWeight.w700, color:Colors.white, letterSpacing: -0.3);
  static const TextStyle heading = TextStyle(fontSize:24, fontWeight:FontWeight.w700, color:Colors.white, letterSpacing: -0.8);
  static const TextStyle subheading = TextStyle(fontSize:15, fontWeight:FontWeight.w600, color:Colors.white, letterSpacing: 3.5);
  static const TextStyle body = TextStyle(fontSize:14, color: Color(0xFFA7AFBF));
  static const TextStyle hint = TextStyle(fontSize:13, color: Color(0xFFA8B0C0));
  static const TextStyle label = TextStyle(fontSize:14, fontWeight:FontWeight.w500, color: Color(0xFFA7AFBF));
  static const TextStyle inputText = TextStyle(fontSize:17, fontWeight:FontWeight.w500, color: Colors.white);
  static const TextStyle supporting = TextStyle(fontSize:13, fontWeight:FontWeight.w400, color: Color(0xFF72798A));
}
