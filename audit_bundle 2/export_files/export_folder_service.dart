import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:qa_genie/core/error/exceptions.dart';
// ============================================================
// FILE: lib/features/export/folder/export_folder_service.dart
// ============================================================

/// ===============================================================
///
/// EXPORT FOLDER SERVICE
///
/// PURPOSE:
/// - Centralized export storage authority
/// - Prevent scattered filesystem access
/// - Stable temp/export directory resolution
/// - Future migration-safe
///
/// STORAGE STRATEGY:
/// - TEMP EXPORTS:
///   Used for sharing/export flow
///
/// - PERSISTENT EXPORTS:
///   Optional future upgrade
///
/// ===============================================================
class ExportFolderService {
  const ExportFolderService._();

  // ============================================================
  // TEMP DIRECTORY
  // ============================================================

  static Future<Directory> getTempDirectory() async {
    try {
      final dir = await getTemporaryDirectory();

      final exportDir = Directory('${dir.path}/qa_genie_exports');

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      return exportDir;
    } catch (e) {
      throw ExportException('Failed to access temp export directory: $e');
    }
  }

  // ============================================================
  // APP DOCUMENT DIRECTORY
  // ============================================================

  static Future<Directory> getPersistentDirectory() async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      final exportDir = Directory('${dir.path}/qa_genie_exports');

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      return exportDir;
    } catch (e) {
      throw ExportException('Failed to access persistent export directory: $e');
    }
  }

  // ============================================================
  // CLEAN TEMP EXPORTS
  // ============================================================

  static Future<void> clearTempExports() async {
    try {
      final dir = await getTempDirectory();

      if (!await dir.exists()) {
        return;
      }

      final files = dir.listSync();

      for (final entity in files) {
        try {
          if (entity is File) {
            await entity.delete();
          }
        } catch (_) {}
      }
    } catch (_) {
      // Silent cleanup failure
    }
  }

  // ============================================================
  // EXPORT FILE EXISTS
  // ============================================================

  static Future<bool> fileExists(
    String fileName, {
    required String extension,
    bool persistent = false,
  }) async {
    try {
      final dir = persistent
          ? await getPersistentDirectory()
          : await getTempDirectory();

      final file = File('${dir.path}/$fileName.$extension');

      return file.exists();
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // RESOLVE EXPORT FILE
  // ============================================================

  static Future<File> resolveFile(
    String fileName, {
    required String extension,
    bool persistent = false,
  }) async {
    final dir = persistent
        ? await getPersistentDirectory()
        : await getTempDirectory();

    return File('${dir.path}/$fileName.$extension');
  }
}
