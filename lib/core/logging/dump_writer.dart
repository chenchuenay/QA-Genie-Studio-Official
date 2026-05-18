import 'dart:io';
import 'logging_config.dart';
import 'storage_telemetry.dart';

class DumpWriter {
  static final StorageTelemetry telemetry = StorageTelemetry();

  static Future<bool> writePipeline(String content, String filePath) async {
    if (!LoggingConfig.forensicLogging) return true;

    final stopwatch = Stopwatch()..start();
    try {
      final file = File(filePath);
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final tempFile = File('$filePath.tmp');
      await tempFile.writeAsString(content, flush: true);
      
      // Sync to disk if possible (Dart File doesn't have a direct 'sync' but flush: true is close)
      
      if (await file.exists()) {
        await file.delete();
      }

      await tempFile.rename(filePath);
      
      stopwatch.stop();
      telemetry.recordSuccess(stopwatch.elapsedMilliseconds);
      return true;
    } catch (e) {
      stopwatch.stop();
      final isDiskFull = e.toString().contains('No space left on device');
      final isPermission = e.toString().contains('Permission denied');
      telemetry.recordFailure(diskFull: isDiskFull, permissionError: isPermission);
      return false;
    }
  }

  static Future<void> appendAnalytical(String content, String filePath) async {
    if (!LoggingConfig.forensicLogging) return;

    final stopwatch = Stopwatch()..start();
    try {
      final file = File(filePath);
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      if (await file.exists()) {
        final size = await file.length();
        if (size > LoggingConfig.analyticalArchiveLimitBytes) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final archiveName = '${file.path}_$timestamp.archive';
          await file.rename(archiveName);
        }
      }

      await file.writeAsString(content, mode: FileMode.append, flush: true);
      
      stopwatch.stop();
      telemetry.recordSuccess(stopwatch.elapsedMilliseconds);
    } catch (e) {
      stopwatch.stop();
      final isDiskFull = e.toString().contains('No space left on device');
      final isPermission = e.toString().contains('Permission denied');
      telemetry.recordFailure(diskFull: isDiskFull, permissionError: isPermission);
    }
  }

  static Future<bool> writeCorePipeline(String content) async {
    return writePipeline(content, LoggingConfig.pipelineFilePath('core'));
  }

  static Future<bool> writeProPipeline(String content) async {
    return writePipeline(content, LoggingConfig.pipelineFilePath('pro'));
  }

  static Future<void> appendCoreAnalytical(String content) async {
    return appendAnalytical(content, LoggingConfig.analyticalFilePath('core'));
  }

  static Future<void> appendProAnalytical(String content) async {
    return appendAnalytical(content, LoggingConfig.analyticalFilePath('pro'));
  }
}
