import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';

Future<T?> showBlurredDialog<T>(BuildContext context, {required WidgetBuilder builder}) {
  // Skip blur on Android < 31 (GPU host buffer OOM risk) and low-RAM devices
  final useBlur = !Platform.isAndroid ||
      (Platform.isAndroid && _androidVersion() >= 31);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(useBlur ? 0.5 : 0.7),
    pageBuilder: (_, __, ___) {
      Widget child = Center(
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
