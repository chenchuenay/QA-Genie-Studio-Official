import 'dart:io';
import 'package:excel/excel.dart';
import 'package:qa_genie/features/export/folder/export_folder_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';

class ExcelAdapter {
  // Steps are preserved in the order returned by the API.
  // No re-sorting is performed, ensuring consistency across all export formats.

  static Future<void> export(
    List<TestCaseModel> cases, {
    required String fileName,
    required String moduleName,
    required String featureName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Test Cases'];
    final rows = ExportMapper.toExcel(
      cases.map((tc) => tc.copy()).toList(),
      moduleName: moduleName,
      featureName: featureName,
    );
    for (final row in rows) {
      sheet.appendRow(row.map(TextCellValue.new).toList());
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('Excel generation failed');
    final dir = await ExportFolderService.getTempDirectory();
    final file = File('${dir.path}/$fileName.xlsx');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)]);
  }
}
