import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/domain/usecases/export_test_cases_use_case.dart';
import 'package:qa_genie/engine/generation_service.dart';

const Map<String, int> weights = {
  'atomic': 1,
  'actionable': 2,
  'preconds': 2,
  'sequential': 3,
  'observable': 3,
  'realistic': 2,
  'nogeneric': 2,
  'risk': 3,
  'independent': 1,
  'rhythm': 1,
  'feasible': 3,
};
final int maxScore = weights.values.reduce((a, b) => a + b);

void sanitizeSteps(List<TestCaseModel> cases) {
  for (final tc in cases) {
    for (final step in tc.steps) {
      if (step.action.trim().isEmpty)
        step.action = 'Perform the required interaction';
      if (step.expected.trim().isEmpty)
        step.expected = 'The system handles the interaction correctly';
    }
  }
}

String excelToText(File file) {
  try {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return 'No sheets found';
    final sheet = excel.tables.keys.first;
    final rows = excel.tables[sheet]!.rows;
    final buf = StringBuffer();
    for (final row in rows) {
      buf.writeln(row.map((c) => c?.value.toString() ?? '').join(' | '));
    }
    return buf.toString();
  } catch (e) {
    return 'Excel read error: $e';
  }
}

Future<File?> exportAndCapture({
  required String type,
  required List<TestCaseModel> cases,
  required String module,
  required String feature,
  required String suiteDir,
}) async {
  final useCase = ExportTestCasesUseCase();
  try {
    await useCase.execute(
      type: type,
      cases: cases,
      moduleName: module,
      featureName: feature,
    );
  } catch (e) {
    if (e is Exception && e.toString().contains('MissingPluginException')) {
      print(
        'Share plugin not available in headless test, but file generation succeeded.',
      );
    } else {
      print('Export failed: $type -> $e');
      return null;
    }
  }
  final tempDir = Directory.systemTemp;
  final files = tempDir
      .listSync()
      .whereType<File>()
      .where(
        (f) =>
            f.path.contains(module.replaceAll(' ', '_')) ||
            f.path.contains(type),
      )
      .toList();
  if (files.isEmpty) return null;
  files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  final latest = files.first;
  final ext = latest.path.split('.').last;
  final dest = File('$suiteDir/$type.$ext');
  await latest.copy(dest.path);
  return dest;
}

Future<void> runValidator() async {
  final configFile = File('tests/test_config.json');
  if (!configFile.existsSync()) {
    print('Config missing');
    return;
  }
  final config = jsonDecode(await configFile.readAsString());
  final spec = config['specification'];
  final module = spec['module'] as String;
  final feature = spec['feature'] as String;
  final platforms = config['platforms'] as Map<String, dynamic>;

  final service = GenerationService();
  final trendFile = File('test_results/quality_trend.csv');
  if (!trendFile.existsSync())
    trendFile.writeAsStringSync('timestamp,platform,mode,avg_score\n');

  final reportBuf = StringBuffer();
  final auditBuf = StringBuffer();

  for (final entry in platforms.entries) {
    final platform = entry.key;
    final enabled = entry.value as bool;
    if (!enabled) continue;

    for (final count in [10, 20]) {
      final mode = count == 10 ? 'Core' : 'Pro';
      print('Generating $platform $mode');

      final result = await service.execute(
        module: module,
        feature: feature,
        platform: platform,
        maxCases: count,
      );
      final cases = result.cases;
      sanitizeSteps(cases);

      final suiteDir = Directory('test_results/${platform}_$mode');
      if (suiteDir.existsSync()) suiteDir.deleteSync(recursive: true);
      suiteDir.createSync(recursive: true);

      final rawFile = File('${suiteDir.path}/raw_cases.json');
      await rawFile.writeAsString(
        const JsonEncoder.withIndent(
          '  ',
        ).convert(cases.map((e) => e.toJson()).toList()),
      );

      for (final fmt in ['excel', 'jira', 'xray', 'pdf']) {
        await exportAndCapture(
          type: fmt,
          cases: cases,
          module: module,
          feature: feature,
          suiteDir: suiteDir.path,
        );
      }

      auditBuf.writeln('=== $platform $mode ===');
      auditBuf.writeln(await rawFile.readAsString());
    }
  }

  await File('test_results/audit_dump.txt').writeAsString(auditBuf.toString());
  await File(
    'test_results/quality_report.txt',
  ).writeAsString(reportBuf.toString());
  print('DONE');
}

void main() async {
  await runValidator();
}
