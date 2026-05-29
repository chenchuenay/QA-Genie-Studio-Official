import 'dart:math';
import 'exceptions.dart';
import 'ui_error_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ErrorSource { auth, bugReportUi, exportEngine, generationEngine, unknown }

enum ErrorStage { authentication, submit, export, generation, unknown }

enum ErrorSeverity { info, warning, error, fatal }

class UiErrorService {
  UiErrorService._();

  static final Random _random = Random.secure();

  static void show({
    required String title,
    required String message,
    String category = 'general',
    Object? exception,
    StackTrace? stackTrace,
    bool isFatal = false,
  }) {
    final event = UiErrorEvent(
      id: _generateId(),
      title: title.trim(),
      message: _sanitize(message),
      category: category.trim().toLowerCase(),
      timestamp: DateTime.now(),
      exception: exception,
      stackTrace: stackTrace,
      isFatal: isFatal,
    );

    UiErrorStore.push(event);

    debugPrint('''
[QA_GENIE_UI_ERROR]
id=${event.id}
category=${event.category}
fatal=${event.isFatal}
title=${event.title}
message=${event.message}
timestamp=${event.timestamp.toIso8601String()}
''');

    if (exception != null) {
      debugPrint('exception=$exception');
    }

    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  static void handle(
    Object error, {
    StackTrace? stackTrace,
    String? fallbackMessage,
    String category = 'general',
    bool isFatal = false,
  }) {
    if (error is AppException) {
      show(
        title: error.runtimeType.toString(),
        message: error.message,
        category: category,
        exception: error,
        stackTrace: stackTrace,
        isFatal: isFatal,
      );

      return;
    }

    show(
      title: 'Unexpected Error',
      message:
          fallbackMessage ??
          'Something went wrong while processing the request.',
      category: category,
      exception: error,
      stackTrace: stackTrace,
      isFatal: isFatal,
    );
  }

  static void logAndShow({
    required BuildContext context,
    required ErrorSource source,
    required String screen,
    required ErrorStage stage,
    required ErrorSeverity severity,
    required String userMessage,
    Object? error,
    StackTrace? stack,
  }) {
    show(
      title: _titleFor(severity),
      message: userMessage,
      category: '${source.name}.${stage.name}.$screen',
      exception: error,
      stackTrace: stack,
      isFatal: severity == ErrorSeverity.fatal,
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(userMessage)));
  }

  static String userFriendlyMessage(Object error) {
    if (error is NetworkException) {
      return 'Network connection failed. Please check connectivity.';
    }

    if (error is GenerationException) {
      return 'Test case generation failed. Please retry.';
    }

    if (error is ExportException) {
      return 'Export failed. Please retry the export.';
    }

    if (error is ValidationException) {
      return 'Validation failed. Please review the provided data.';
    }

    if (error is SecurityException) {
      return 'Request blocked due to security validation.';
    }

    return 'Something unexpected happened.';
  }

  static String _generateId() {
    final randomHex = List.generate(
      6,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join().toUpperCase();

    return 'ERR-$randomHex';
  }

  static String _sanitize(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _titleFor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return 'Info';
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.fatal:
        return 'Fatal Error';
    }
  }
}
