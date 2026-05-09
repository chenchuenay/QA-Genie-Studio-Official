import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ExportFolderService {
  static Future<Directory> getTestCaseDirectory(String format) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/QA_Genie/TestCases/$format');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> getSummaryReportDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/QA_Genie/SummaryReports');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
