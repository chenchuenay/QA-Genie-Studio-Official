import 'package:flutter/material.dart';
import '../../core/utils/screen_utils.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final bool includeSafeArea;
  final double maxWidth;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.includeSafeArea = true,
    this.maxWidth = 1100,
  });

  @override
  Widget build(BuildContext context) {
    final maxW = ScreenUtils.width(context) >= 1200
        ? maxWidth
        : double.infinity;
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: child,
      ),
    );
    if (includeSafeArea) {
      content = SafeArea(child: content);
    }
    return content;
  }
}
