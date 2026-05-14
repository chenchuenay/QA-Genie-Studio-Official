import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ExportFolderService {

  /// Returns a temporary directory that works in both headless tests and normal runtime
  static Future<Directory> getTempDirectory() async {
    if (const bool.fromEnvironment('QA_GENIE_TEST', defaultValue: false)) {
      return Directory.systemTemp;
    }
    return getTemporaryDirectory();
  }

  static Future<Directory> getTestCaseDirectory(String format) async {
    final base = await () async {
      if (const bool.fromEnvironment('QA_GENIE_TEST', defaultValue: false)) {
        return Directory.systemTemp;
      }
      return getApplicationDocumentsDirectory();
    }();
    final dir = Directory('${base.path}/QA_Genie/TestCases/$format');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> getSummaryReportDirectory() async {
    final base = await () async {
      if (const bool.fromEnvironment('QA_GENIE_TEST', defaultValue: false)) {
        return Directory.systemTemp;
      }
      return getApplicationDocumentsDirectory();
    }();
    final dir = Directory('${base.path}/QA_Genie/SummaryReports');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
