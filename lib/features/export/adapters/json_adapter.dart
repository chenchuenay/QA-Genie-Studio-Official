import 'dart:convert';
import 'package:qa_app/data/models/test_case_model.dart';
import 'package:qa_app/features/export/common/export_mapper.dart';
import '../writers/file_writer.dart';

class JsonAdapter {
  // Steps are preserved in the order returned by the API.
  // No re-sorting is performed, ensuring consistency across all export formats.

  static Future<void> export(
    List<TestCaseModel> cases, {
    required String fileName,
    required String moduleName,
    required String featureName,
  }) async {
    final data = ExportMapper.toXray(
      cases.map((tc) => tc.copy()).toList(),
      moduleName: moduleName,
      featureName: featureName,
    );
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await FileWriter.writeAndShare(jsonString, fileName, extension: 'json');
  }
}
