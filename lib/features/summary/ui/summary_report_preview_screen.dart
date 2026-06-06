import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/core/error/ui_error_service.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/features/monetization/ads/ad_service.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/domain/usecases/export_test_cases_use_case.dart';

class SummaryReportPreviewScreen extends StatelessWidget {
  final GenerationSession session;
  final String moduleName;
  final String feature;
  final String platform;
  final String testerName;
  final String environment;

  const SummaryReportPreviewScreen({
    super.key,
    required this.session,
    required this.moduleName,
    required this.feature,
    required this.platform,
    required this.testerName,
    required this.environment,
  });

  int get _total => session.testCases.length;
  int get _passed => session.testCases.where((c) => c.status == 'Pass').length;
  int get _failed => session.testCases.where((c) => c.status == 'Fail').length;
  int get _blocked =>
      session.testCases.where((c) => c.status == 'Blocked').length;

  String get _passRate {
    final executed = _passed + _failed + _blocked;
    return executed == 0
        ? '0.0'
        : (_passed / executed * 100).toStringAsFixed(1);
  }

  Future<void> _exportPDF(BuildContext context) async {
    final isPro = await UsageManager.isPro();
    String? adToken;
    if (!isPro) {
      adToken = await AdService.showRewardedAd(
        adUnitId: 'ca-app-pub-.../summary_export',
        context: context,
      );
      if (adToken == null) return;
    }
    try {
      final exportUseCase = ExportTestCasesUseCase();
      await exportUseCase.exportSummaryReport(
        cases: session.testCases,
        moduleName: moduleName,
        featureName: feature,
        platform: platform,
        testerName: testerName,
        environment: environment,
        context: context,
        adToken: adToken,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summary report exported!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e, stack) {
      UiErrorService.logAndShow(
        context: context,
        source: ErrorSource.exportEngine,
        screen: 'SummaryReportPreviewScreen',
        stage: ErrorStage.export,
        severity: ErrorSeverity.error,
        userMessage: 'Export failed: $e',
        error: e,
        stack: stack,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Summary Report Preview',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TEST SUMMARY REPORT',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoRow('Suite', '$moduleName · $feature'),
                  _infoRow('Platform', platform),
                  _infoRow('Date', _currentDate()),
                  if (testerName.isNotEmpty) _infoRow('Tester', testerName),
                  if (environment.isNotEmpty)
                    _infoRow('Environment', environment),
                  const SizedBox(height: 24),
                  _executionSummaryTable(),
                  const SizedBox(height: 24),
                  _priorityBreakdown(),
                  const SizedBox(height: 24),
                  _detailedResultsTable(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _exportPDF(context),
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
                  label: const Text(
                    'Export PDF',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _currentDate() => DateTime.now().toIso8601String().substring(0, 10);

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _executionSummaryTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Execution Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _tableRow(['Metric', 'Value'], isHeader: true),
              _tableRow(['Total', '$_total']),
              _tableRow(['Passed', '$_passed']),
              _tableRow(['Failed', '$_failed']),
              _tableRow(['Blocked', '$_blocked']),
              _tableRow([
                'Not Executed',
                '${_total - _passed - _failed - _blocked}',
              ]),
              _tableRow(['Pass Rate', '$_passRate%']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priorityBreakdown() {
    final cases = session.testCases;
    final high = cases.where((c) => c.priority == 'High').length;
    final medium = cases.where((c) => c.priority == 'Medium').length;
    final low = cases.where((c) => c.priority == 'Low').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        _priorityRow('High', high),
        _priorityRow('Medium', medium),
        _priorityRow('Low', low),
      ],
    );
  }

  Widget _priorityRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _detailedResultsTable() {
    final cases = session.testCases;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Results',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _tableRow([
                'Test Case ID',
                'Title',
                'Priority',
                'Status',
                'Actual Result',
              ], isHeader: true),
              ...cases.map(
                (tc) => _tableRow([
                  tc.id,
                  tc.title,
                  tc.priority,
                  tc.status,
                  tc.actualResult,
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableRow(List<String> cells, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        color: isHeader ? AppColors.card : Colors.transparent,
      ),
      child: Row(
        children: cells.asMap().entries.map((entry) {
          final index = entry.key;
          final cell = entry.value;
          double flex = 1;
          if (index == 0) flex = 1.2;
          if (index == 1) flex = 3;
          if (index == 2) flex = 0.8;
          if (index == 3) flex = 1;
          if (index == 4) flex = 1.5;
          return Expanded(
            flex: flex.toInt(),
            child: Text(
              cell.isEmpty ? '-' : cell,
              style: TextStyle(
                color: isHeader
                    ? AppColors.accent
                    : (cell == 'Pass'
                          ? AppColors.success
                          : (cell == 'Fail' ? AppColors.error : Colors.white)),
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
