import 'dart:io';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qa_genie/core/error/exceptions.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';
import 'package:qa_genie/features/export/folder/export_folder_service.dart';
// ============================================================
// FILE: lib/features/export/adapters/excel_adapter.dart
// ============================================================

/// ===============================================================
///
/// EXCEL ADAPTER
///
/// PURPOSE:
/// - Traditional QA spreadsheet export
/// - Enterprise-compatible XLSX format
/// - Preserves deterministic ordering
///
/// ARCHITECTURAL ROLE:
/// - Pure reader of FinalizedTestCase.
/// - Guarantees invariant field ordering via ExportMapper.
///
/// ===============================================================
class ExcelAdapter {
  const ExcelAdapter._();

  static const _sheetName = 'Test Cases';

  // ============================================================
  // EXPORT
  // ============================================================

  static Future<void> export(
    List<FinalizedTestCase> cases, {
    required String fileName,
    required String moduleName,
    required String featureName,
  }) async {
    try {
      final excel = Excel.createExcel();

      final sheet = excel[_sheetName];

      /// Forensic logic: Direct consumption of FinalizedTestCase to ensure
      /// session edits (actualResult/status) are reflected instantly.
      final rows = ExportMapper.toExcel(
        cases,
        moduleName: moduleName,
        featureName: featureName,
      );

      for (final row in rows) {
        sheet.appendRow(row.map((e) => TextCellValue(e)).toList());
      }

      final bytes = excel.save();

      if (bytes == null) {
        throw const ExportException('Excel generation failed.');
      }

      final dir = await ExportFolderService.getTempDirectory();

      final file = File('${dir.path}/$fileName.xlsx');

      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      throw ExportException('Excel export failed: $e');
    }
  }
}
