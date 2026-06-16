import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/core/error/ui_error_service.dart';
import 'package:qa_genie/shared/widgets/animated_dots.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/shared/widgets/watch_ad_dialog.dart';
import 'package:qa_genie/features/monetization/ads/ad_units.dart';
import 'package:qa_genie/features/monetization/ads/ad_manager.dart';
import 'package:qa_genie/shared/dialogs/export_success_dialog.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/domain/usecases/export_test_cases_use_case.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';

class SummaryReportPreviewScreen extends StatefulWidget {
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

  @override
  State<SummaryReportPreviewScreen> createState() =>
      _SummaryReportPreviewScreenState();
}

class _SummaryReportPreviewScreenState
    extends State<SummaryReportPreviewScreen> {
  bool _isProcessing = false;
  bool _isSharing = false;

  int get _total => widget.session.testCases.length;
  int get _passed =>
      widget.session.testCases.where((c) => c.status == 'Pass').length;
  int get _failed =>
      widget.session.testCases.where((c) => c.status == 'Fail').length;
  int get _blocked =>
      widget.session.testCases.where((c) => c.status == 'Blocked').length;

  String get _passRate {
    final executed = _passed + _failed + _blocked;
    return executed == 0
        ? '0.0'
        : (_passed / executed * 100).toStringAsFixed(1);
  }

  Future<void> _exportPDF(BuildContext context) async {
    if (_isProcessing) return;
    FocusScope.of(context).unfocus();

    final isPro = await UsageManager.isPro();
    String? adToken;

    if (!isPro) {
      final shouldWatch = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) =>
            const WatchAdDialog(featureName: 'Export Summary Report'),
      );
      if (shouldWatch != true) return;

      // Use AdManager to show the rewarded ad
      adToken = await AdManager().showRewardedAd(
        adUnitId: AdUnits.rewardedSummaryExport,
      );
      if (adToken == null) {
        // Show recovery dialog
        AdManager().showStatusDialog(
          context,
          onRetry: () => _exportPDF(context),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      setState(() => _isSharing = true);

      final exportUseCase = ExportTestCasesUseCase();
      await exportUseCase.exportSummaryReport(
        cases: widget.session.testCases,
        moduleName: widget.moduleName,
        featureName: widget.feature,
        platform: widget.platform,
        testerName: widget.testerName,
        environment: widget.environment,
        context: context,
        adToken: adToken,
      );
      await FunctionsService.trackExport(
        summary: true,
        target: 'pdf',
        extension: 'pdf',
      );
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _isSharing = false;
      });

      showBlurredDialog(
        context,
        builder: (ctx) =>
            ExportSuccessDialog(type: 'pdf', moduleName: widget.moduleName),
      );
    } catch (e, stack) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSharing = false;
        });
      }
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
    return ValueListenableBuilder<bool>(
      valueListenable: AdManager().isAdLoading,
      builder: (context, isAdLoading, _) {
        final fullLock = _isProcessing || isAdLoading || _isSharing;

        Widget content = AbsorbPointer(
          absorbing: fullLock,
          child: Scaffold(
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
                    physics: fullLock
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics(),
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
                        _infoRow(
                          'Suite',
                          '${widget.moduleName} · ${widget.feature}',
                        ),
                        _infoRow('Platform', widget.platform),
                        _infoRow('Date', _currentDate()),
                        if (widget.testerName.isNotEmpty)
                          _infoRow('Tester', widget.testerName),
                        if (widget.environment.isNotEmpty)
                          _infoRow('Environment', widget.environment),
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
                        onPressed: fullLock ? null : () => _exportPDF(context),
                        icon: fullLock
                            ? const SizedBox.shrink()
                            : const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.black,
                              ),
                        label: fullLock
                            ? const AnimatedDots(
                                label: '⚡ Processing',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Text(
                                'Export PDF',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: fullLock
                              ? AppColors.accent.withOpacity(0.5)
                              : AppColors.accent,
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
          ),
        );

        if (_isSharing) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: content,
          );
        }
        return content;
      },
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
    final cases = widget.session.testCases;
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
    final cases = widget.session.testCases;
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
