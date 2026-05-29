import 'dart:io';
import 'dart:convert';

class DumpWriter {
  const DumpWriter._();

  static Future<File> writeText({
    required String directory,
    required String fileName,
    required String content,
    bool append = false,
  }) async {
    final dir = Directory(directory);

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final file = File('${dir.path}/$fileName');

    if (append && file.existsSync()) {
      await file.writeAsString(
        content,
        mode: FileMode.append,
        flush: true,
        encoding: utf8,
      );
    } else {
      await file.writeAsString(content, flush: true, encoding: utf8);
    }

    return file;
  }

  static Future<File> writeJson({
    required String directory,
    required String fileName,
    required Object data,
  }) async {
    final pretty = const JsonEncoder.withIndent('  ').convert(data);

    return writeText(directory: directory, fileName: fileName, content: pretty);
  }

  static Future<File> writeForensicDump({
    required String traceId,
    required String category,
    required String content,
  }) async {
    final safeCategory = category.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_]'),
      '_',
    );

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

    return writeText(
      directory: 'qa_forensics/$safeCategory',
      fileName: '${traceId}_$timestamp.txt',
      content: content,
    );
  }

  static Future<void> cleanupOldFiles({
    required String directory,
    int keepLatest = 25,
  }) async {
    final dir = Directory(directory);

    if (!dir.existsSync()) {
      return;
    }

    final files = dir.listSync().whereType<File>().toList();

    if (files.length <= keepLatest) {
      return;
    }

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    final removable = files.skip(keepLatest);

    for (final file in removable) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}
