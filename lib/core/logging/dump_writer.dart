import 'dart:io';

class DumpWriter {
  static Future<bool> writePipeline(String content, String filePath) async {
    final tempFile = File('$filePath.tmp');
    try {
      await tempFile.writeAsString(content, flush: true);
      if (await File(filePath).exists()) {
        await File(filePath).delete();
      }
      await tempFile.rename(filePath);
      return true;
    } catch (e) {
      // silent failure for Phase 0
      return false;
    }
  }

  static Future<void> writeAnalytical(String content, String filePath) async {
    final file = File(filePath);
    await file.writeAsString(content, mode: FileMode.append, flush: true);
  }
}
