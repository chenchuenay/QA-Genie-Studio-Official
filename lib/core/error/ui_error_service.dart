import 'ui_error_store.dart';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/constants.dart';

class UiErrorService {
  static void logAndShow({
    required BuildContext context,
    required ErrorSource source,
    required String screen,
    required ErrorStage stage,
    required ErrorSeverity severity,
    required String userMessage,
    required dynamic error,
    StackTrace? stack,
    bool showSnackBar = true,
    Duration duration = const Duration(seconds: 3),
  }) {
    UiErrorStore().add(
      source: source,
      screen: screen,
      stage: stage,
      severity: severity,
      userMessage: userMessage,
      error: error,
      stack: stack,
    );
    if (showSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          backgroundColor: severity == ErrorSeverity.critical
              ? Colors.redAccent
              : AppColors.error,
          duration: duration,
        ),
      );
    }
  }

  static void logOnly({
    required ErrorSource source,
    required String screen,
    required ErrorStage stage,
    required ErrorSeverity severity,
    required String userMessage,
    required dynamic error,
    StackTrace? stack,
  }) {
    UiErrorStore().add(
      source: source,
      screen: screen,
      stage: stage,
      severity: severity,
      userMessage: userMessage,
      error: error,
      stack: stack,
    );
  }
}
