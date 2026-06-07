import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qa_genie/core/error/exceptions.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';
import 'package:qa_genie/features/export/folder/export_folder_service.dart';

/// EXCEL ADAPTER
/// Traditional QA spreadsheet export (XLSX).
class ExcelAdapter {
  const ExcelAdapter._();

  static const _sheetName = 'Test Cases';

  static Future<void> export(
    List<FinalizedTestCase> cases, {
    required String fileName,
    required String moduleName,
    required String featureName,
  }) async {
    final startTime = DateTime.now();
    debugPrint('📊 EXCEL_ADAPTER: Started export for ${cases.length} cases');
    try {
      final excel = Excel.createExcel();
      final sheet = excel[_sheetName];
      final rows = ExportMapper.toExcel(
        cases,
        moduleName: moduleName,
        featureName: featureName,
      );
      for (final row in rows) {
        sheet.appendRow(row.map((e) => TextCellValue(e)).toList());
      }
      final bytes = excel.save();
      if (bytes == null)
        throw const ExportException('Excel generation failed.');
      final dir = await ExportFolderService.getTempDirectory();
      final file = File('${dir.path}/$fileName.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('✅ EXCEL_ADAPTER: Success in ${duration}ms');
    } catch (e, stack) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('❌ EXCEL_ADAPTER: Failed after ${duration}ms');
      debugPrint('❌ EXCEL_ADAPTER error: $e');
      debugPrint('❌ EXCEL_ADAPTER stack: $stack');
      throw ExportException('Excel export failed: $e');
    }
  }
}
