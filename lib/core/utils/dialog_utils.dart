import 'dart:ui';
import 'package:flutter/material.dart';

/// Shows a dialog with a blurred background.
/// Use this for informational dialogs (guidelines, bug report, preview, etc.).
/// Error / success alerts should NOT use this – they must stay sharp.
void showBlurredDialog(BuildContext context, {required WidgetBuilder builder}) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: builder(ctx),
    ),
  );
}
