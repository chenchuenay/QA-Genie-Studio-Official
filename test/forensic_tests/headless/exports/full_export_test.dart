import 'dart:io';
import '../../support/forensic_runner.dart';
import '../../inputs/generation_inputs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/usecases/export_test_cases_use_case.dart';

void main() {
  test(
    'Export previously generated test cases',
    () async {
      // Load cases saved by generation_pipeline_test.dart (no new AI call)
      final cases = await ForensicRunner.loadLastGeneratedCases();

      final exportUseCase = ExportTestCasesUseCase();
      final exportDir = Directory('test_results/export_files');
      if (!exportDir.existsSync()) exportDir.createSync(recursive: true);

      // Export all formats – moduleName and featureName are automatically extracted from cases
      await exportUseCase.execute(type: 'excel', cases: cases);
      await exportUseCase.execute(type: 'jira', cases: cases);
      await exportUseCase.execute(type: 'xray', cases: cases);
      await exportUseCase.execute(type: 'pdf', cases: cases);

      await exportUseCase.exportSummaryReport(
        cases: cases,
        platform: GenerationInputs.platforms[GenerationInputs.platformIndex],
        testerName: 'QA Tester',
        environment: 'Staging',
      );

      // No assertions – test passes if no exception is thrown.
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
