import 'dart:ui';
import 'package:flutter/material.dart';

void showBlurredDialog(BuildContext context, {required WidgetBuilder builder}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.5),
    pageBuilder: (_, __, ___) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Builder(builder: builder),
          ),
        ),
      );
    },
  );
}
