import 'dart:ui';
import 'package:flutter/material.dart';

Future<T?> showBlurredDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  AlignmentGeometry alignment = Alignment.center,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.5),
    pageBuilder: (_, __, ___) {
      return Align(
        alignment: alignment,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: Builder(builder: builder),
          ),
        ),
      );
    },
  );
}
