import 'package:flutter/material.dart';
class AppColors {
  static const background = Color(0xFF080808);
  static const surface = Color(0xFF111115);
  static const accent = Color(0xFF00F0FF);
  static const accentLight = Color(0xFF80F8FF);
  static const card = Color(0xFF1A1A1F);
  static const border = Color(0x22FFFFFF);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFB0B8C1);
  static const textHint = Color(0xFF5C6268);
  static const success = Color(0xFF00E676);
  static const warning = Color(0xFFFFCA28);
  static const error = Color(0xFFFF5252);
  static const blue = Color(0xFF42A5F5);
  static const orange = Color(0xFFFFA726);
  static const purple = Color(0xFFAB47BC);
}
class AppSpacing { static const double xs=4, sm=8, md=16, lg=24, xl=32; }
class AppRadius { static const double sm=8, md=12, lg=16, xl=20; }
class AppText {
  static const TextStyle button = TextStyle(fontSize:16, fontWeight:FontWeight.bold, color:Colors.white);
  static const TextStyle heading = TextStyle(fontSize:28, fontWeight:FontWeight.bold, color:Colors.white);
  static const TextStyle subheading = TextStyle(fontSize:18, fontWeight:FontWeight.bold, color:Colors.white);
  static const TextStyle body = TextStyle(fontSize:14, color: Color(0xFFB0B8C1));
  static const TextStyle hint = TextStyle(fontSize:13, color: Color(0xFF5C6268));
}
