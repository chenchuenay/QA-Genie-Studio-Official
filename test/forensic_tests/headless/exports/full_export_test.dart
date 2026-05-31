import 'dart:io';
import '../../support/forensic_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import '../inputs/generation_inputs.dart'; // ✅ correct path
import 'package:qa_genie/domain/usecases/export_test_cases_use_case.dart';

void main() {
  test('Export previously generated test cases', () async {
    final cases = await ForensicRunner.loadLastGeneratedCases();

    final exportUseCase = ExportTestCasesUseCase();
    final exportDir = Directory('test_results/export_files');
    if (!exportDir.existsSync()) exportDir.createSync(recursive: true);

    await exportUseCase.execute(type: 'excel', cases: cases);
    await exportUseCase.execute(type: 'jira', cases: cases);
    await exportUseCase.execute(type: 'xray', cases: cases);
    await exportUseCase.execute(type: 'pdf', cases: cases);

    // Summary report export skipped as it requires BuildContext (not available in headless test)
  }, timeout: const Timeout(Duration(minutes: 10)));
}