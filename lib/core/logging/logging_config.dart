import 'dart:io';

class LoggingConfig {
  static const bool forensicLogging = bool.fromEnvironment(
    'FORENSIC_LOGGING',
    defaultValue: false,
  );

  static const int schemaVersion = 1;
  static const String encoding = 'UTF-8';
  static const int rawResponseLimit = 50000;
  static const int analyticalArchiveLimitBytes = 10 * 1024 * 1024;

  static String get _basePath {
    try {
      if (Platform.isAndroid) {
        return '/data/data/com.enaykumar.qagenie';
      }
    } catch (_) {}
    return '.';
  }

  static String pipelineFilePath(String mode) {
    return '$_basePath/cache/test_results/${mode}_pipeline.txt';
  }

  static String analyticalFilePath(String mode) {
    return '$_basePath/cache/test_results/${mode}_analytical_logs.txt';
  }
}
