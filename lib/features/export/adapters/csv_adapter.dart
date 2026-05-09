import 'package:qa_app/data/models/test_case_model.dart';
import 'package:qa_app/features/export/common/export_mapper.dart';
import '../writers/file_writer.dart';

class CsvAdapter {
  static String _escape(String field) {
    return '"${field.replaceAll('\\n', ' ').replaceAll('"', '""')}"';
  }

  static Future<void> export(
    List<TestCaseModel> cases, {
    required String fileName,
    required String moduleName,
    required String featureName,
  }) async {
    final rows = ExportMapper.toJira(
      safeCases(cases),
      featureName: featureName,
    );
    final buf = StringBuffer();
    for (final row in rows) {
      buf.writeln(row.map(_escape).join(','));
    }
    await FileWriter.writeAndShare(buf.toString(), fileName, extension: 'csv');
  }

  static List<TestCaseModel> safeCases(List<TestCaseModel> cases) =>
      List<TestCaseModel>.from(cases.map((tc) => tc.copy()));
}
