import 'package:flutter/material.dart';

class ScreenUtils {
  static double width(BuildContext c) => MediaQuery.of(c).size.width;
  static double height(BuildContext c) => MediaQuery.of(c).size.height;

  static bool isDesktop(BuildContext c) => width(c) >= 1024;
  static bool isTablet(BuildContext c) => width(c) >= 600 && width(c) < 1024;
  static bool isPhone(BuildContext c) => width(c) < 600;
  static bool useNavigationRail(BuildContext c) => width(c) >= 1024;

  static double padding(BuildContext c) {
    if (isDesktop(c)) return 40;
    if (isTablet(c)) return 28;
    return 16;
  }

  static double contentWidth(BuildContext c) {
    final w = width(c);
    if (w >= 1200) return 1100;
    if (w >= 840) return 760;
    return w;
  }
}
