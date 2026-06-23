import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';

Future<T?> showBlurredDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  AlignmentGeometry alignment = Alignment.center,
}) {
  // Skip blur on Android < 12 (API 31, GPU host buffer OOM risk) and low-RAM devices
  final useBlur = !Platform.isAndroid ||
      (Platform.isAndroid && _androidVersion() >= 12);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(useBlur ? 0.5 : 0.7),
    pageBuilder: (_, __, ___) {
      Widget child = Align(
        alignment: alignment,
        child: Material(
          color: Colors.transparent,
          child: Builder(builder: builder),
        ),
      );
      if (useBlur) {
        child = BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: child,
        );
      }
      return child;
    },
  );
}

int _androidVersion() {
  try {
    return int.parse(Platform.version.split('.').first);
  } catch (_) {
    return 0;
  }
}
