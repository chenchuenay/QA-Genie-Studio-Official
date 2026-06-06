import 'package:flutter/foundation.dart';

/// Centralized error capture utilities for forensic logging.
/// All errors are printed to debugPrint for terminal visibility.

class ErrorCaptureUtils {
  const ErrorCaptureUtils._();

  static void logError({
    required String source,
    required dynamic error,
    StackTrace? stack,
    String? additionalInfo,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🔴 FORENSIC_ERROR [$source]: $error');
    if (additionalInfo != null) buffer.writeln('   Info: $additionalInfo');
    if (stack != null) buffer.writeln('   Stack: $stack');
    debugPrint(buffer.toString());
  }

  static String? extractNetworkErrorType(dynamic error) {
    if (error == null) return null;
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('socket') ||
        errorStr.contains('connection refused')) {
      return 'connection_refused';
    }
    if (errorStr.contains('timeout')) return 'timeout';
    if (errorStr.contains('dns') || errorStr.contains('host'))
      return 'dns_error';
    if (errorStr.contains('certificate')) return 'tls_error';
    return null;
  }

  static int? extractHttpStatusCode(dynamic error) {
    if (error == null) return null;
    final errorStr = error.toString();
    final match = RegExp(r'statusCode[^\d]*(\d{3})').firstMatch(errorStr);
    if (match != null) return int.tryParse(match.group(1)!);
    if (errorStr.contains('429')) return 429;
    if (errorStr.contains('503')) return 503;
    if (errorStr.contains('500')) return 500;
    return null;
  }

  static String truncate(String input, int maxLength) {
    if (input.length <= maxLength) return input;
    return '${input.substring(0, maxLength)}...[truncated]';
  }
}
