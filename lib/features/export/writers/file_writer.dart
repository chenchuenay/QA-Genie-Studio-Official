import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:qa_genie/core/error/exceptions.dart';
import 'package:qa_genie/features/export/writers/share_service.dart';
import 'package:qa_genie/features/export/folder/export_folder_service.dart';
// ============================================================
// FILE: lib/features/export/writers/file_writer.dart
// ============================================================





/// ===============================================================
///
/// FILE WRITER
///
/// PURPOSE:
/// - Centralized export writing layer
/// - Prevent duplicate filesystem logic
/// - Ensure atomic write behavior
/// - Safe UTF-8 persistence
///
/// ===============================================================
class FileWriter {
  const FileWriter._();

  // ============================================================
  // WRITE + SHARE
  // ============================================================

  static Future<File> writeAndShare(
    String content,
    String fileName, {
    required String extension,
  }) async {
    try {
      final file = await write(content, fileName, extension: extension);

      await ShareService.shareFile(file);

      return file;
    } catch (e) {
      throw ExportException('File write/share failed: $e');
    }
  }

  // ============================================================
  // WRITE
  // ============================================================

  static Future<File> write(
    String content,
    String fileName, {
    required String extension,
  }) async {
    try {
      final dir = await ExportFolderService.getTempDirectory();

      final sanitizedName = _sanitizeFileName(fileName);

      final fullPath = p.join(dir.path, '$sanitizedName.$extension');

      final file = File(fullPath);

      await file.writeAsString(content, flush: true);

      return file;
    } catch (e) {
      throw ExportException('File write failed: $e');
    }
  }

  // ============================================================
  // SANITIZE
  // ============================================================

  static String _sanitizeFileName(String input) {
    final sanitized = input
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    if (sanitized.isEmpty) {
      return 'qa_genie_export';
    }

    return sanitized;
  }
}
