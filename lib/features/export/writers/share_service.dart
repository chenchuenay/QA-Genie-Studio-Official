import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:qa_genie/core/error/exceptions.dart';
// ============================================================
// FILE: lib/features/export/writers/share_service.dart
// ============================================================




/// ===============================================================
///
/// SHARE SERVICE
///
/// PURPOSE:
/// - Centralized native share handling
/// - Prevent duplicated SharePlus logic
/// - Future-safe abstraction layer
///
/// ===============================================================
class ShareService {
  const ShareService._();

  // ============================================================
  // SHARE FILE
  // ============================================================

  static Future<void> shareFile(File file) async {
    try {
      if (!await file.exists()) {
        throw const ExportException('Cannot share missing file.');
      }

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      throw ExportException('File sharing failed: $e');
    }
  }

  // ============================================================
  // SHARE MULTIPLE FILES
  // ============================================================

  static Future<void> shareFiles(List<File> files) async {
    try {
      if (files.isEmpty) {
        throw const ExportException('No files available to share.');
      }

      final existing = <XFile>[];

      for (final file in files) {
        if (await file.exists()) {
          existing.add(XFile(file.path));
        }
      }

      if (existing.isEmpty) {
        throw const ExportException('No valid files found to share.');
      }

      await Share.shareXFiles(existing);
    } catch (e) {
      throw ExportException('Multi-file sharing failed: $e');
    }
  }
}
