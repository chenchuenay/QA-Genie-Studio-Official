import 'package:flutter/material.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/usecases/export_test_cases_use_case.dart';


class ExportRepository {
  final ExportTestCasesUseCase _exportUseCase;

  const ExportRepository({required ExportTestCasesUseCase exportUseCase}) : _exportUseCase = exportUseCase;

  Future<void> export({
    required String format,
    required List<FinalizedTestCase> cases,
    required String moduleName,
    required String featureName,
  }) async {
    await _exportUseCase.execute(
      type: format,
      cases: cases,
      moduleName: moduleName,
      featureName: featureName,
    );
  }

  Future<void> exportSummary({
    required List<FinalizedTestCase> cases,
    required String moduleName,
    required String featureName,
    required String platform,
    required String testerName,
    required String environment,
    required BuildContext context,
  }) async {
    await _exportUseCase.exportSummaryReport(
      cases: cases,
      moduleName: moduleName,
      featureName: featureName,
      platform: platform,
      testerName: testerName,
      environment: environment,
      context: context,
    );
  }
}