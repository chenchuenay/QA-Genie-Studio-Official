import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/core/error/ui_error_service.dart';
import 'package:qa_genie/app/startup/app_dependencies.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/shared/dialogs/export_bottom_sheet.dart';
import 'package:qa_genie/domain/usecases/save_suite_use_case.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/shared/dialogs/export_success_dialog.dart';
import 'package:qa_genie/features/summary/ui/summary_report_screen.dart';
import 'package:qa_genie/domain/usecases/export_test_cases_use_case.dart';
import 'package:qa_genie/features/generation/ui/widgets/master_table.dart';

class PreviewScreen extends StatefulWidget {
  final GenerationSession session;
  final String moduleName;
  final String feature;
  final String platform;
  final int suiteId;

  const PreviewScreen({
    super.key,
    required this.session,
    required this.moduleName,
    required this.feature,
    required this.platform,
    required this.suiteId,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with WidgetsBindingObserver {
  final ExportTestCasesUseCase _exportUseCase = ExportTestCasesUseCase();
  final SaveSuiteUseCase _saveUseCase = AppDependencies.saveSuiteUseCase;

  Timer? _debounceTimer;
  bool isEditable = false;
  bool _hasUnsaved = false;
  List<FinalizedTestCase>? _backupCases;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ... keep audit logs (unchanged)
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _forceSave();
  }

  Future<void> _forceSave() async {
    if (_hasUnsaved) await _autoSave();
  }

  Future<void> _autoSave() async {
    if (!_hasUnsaved) return;
    await _saveUseCase.saveSuite(
      suiteId: widget.suiteId,
      cases: widget.session.testCases,
    );
    if (!mounted) return;
    setState(() => _hasUnsaved = false);
  }

  Future<bool> _onWillPop() async {
    await _forceSave();
    return true;
  }

  void _markUnsaved() {
    if (!mounted) return;
    setState(() => _hasUnsaved = true);
  }

  void _toggleEdit() {
    if (!isEditable) {
      _backupCases = widget.session.testCases
          .map((tc) => tc.copyWith())
          .toList();
    }
    setState(() => isEditable = !isEditable);
  }

  void _undoAndExitEdit() {
    if (_backupCases != null) {
      widget.session.testCases.clear();
      widget.session.testCases.addAll(_backupCases!);
      _backupCases = null;
      _hasUnsaved = false;
      setState(() {});
    }
    setState(() => isEditable = false);
  }

  Future<void> _saveAndExitEdit() async {
    try {
      await _autoSave();
      if (!mounted) return;
      setState(() {
        isEditable = false;
        _backupCases = null;
      });
    } catch (e, stack) {
      UiErrorService.logAndShow(
        context: context,
        source: ErrorSource.exportEngine,
        screen: 'PreviewScreen',
        stage: ErrorStage.unknown,
        severity: ErrorSeverity.error,
        userMessage: 'Save failed: $e',
        error: e,
        stack: stack,
      );
    }
  }

  Future<void> _export(String type, String? adToken) async {
    await _autoSave();
    try {
      await _exportUseCase.execute(
        type: type,
        cases: widget.session.testCases,
        moduleName: widget.moduleName,
        featureName: widget.feature,
        adToken: adToken,
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => ExportSuccessDialog(
          type: type,
          moduleName: widget.moduleName,
        ),
      );
    } catch (e, stackTrace) {
      UiErrorService.logAndShow(
        context: context,
        source: ErrorSource.exportEngine,
        screen: 'PreviewScreen',
        stage: ErrorStage.export,
        severity: ErrorSeverity.error,
        userMessage: 'Export failed: $e',
        error: e,
        stack: stackTrace,
      );
    }
  }

  Future<void> _openExport() async {
    await _autoSave();
    if (!mounted) return;
    await showModalBottomSheet<List<FinalizedTestCase>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportBottomSheet(
        cases: widget.session.testCases,
        moduleName: widget.moduleName,
        featureName: widget.feature,
        onSave: (updated) async {
          // Update the main list
          widget.session.testCases = List.from(updated);
          // Save to database immediately
          await _saveUseCase.saveSuite(
            suiteId: widget.suiteId,
            cases: widget.session.testCases,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Changes saved'),
                backgroundColor: AppColors.success,
              ),
            );
            // Force UI rebuild
            setState(() {});
          }
        },
        onExport: (type, updated, adToken) async {
          widget.session.testCases = List.from(updated);
          await _saveUseCase.saveSuite(
            suiteId: widget.suiteId,
            cases: widget.session.testCases,
          );
          // Trigger the export
          await _export(type, adToken);
          // Finally pop the bottom sheet
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _openSummary() async {
    await _autoSave();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryReportScreen(
          session: widget.session,
          moduleName: widget.moduleName,
          feature: widget.feature,
          platform: widget.platform,
          suiteId: widget.suiteId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 8.0;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(4, topPadding, 16, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.surface, AppColors.background],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () async {
                          if (await _onWillPop() && mounted)
                            Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Suite",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (!isEditable) ...[
                        OutlinedButton.icon(
                          onPressed: _openSummary,
                          icon: const Icon(
                            Icons.description,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          label: const Text(
                            'Summary Report',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.accent,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: AppColors.accent.withOpacity(0.08),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _toggleEdit,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: const Text(
                            'EDIT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (isEditable) ...[
                        TextButton(
                          onPressed: _undoAndExitEdit,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: _saveAndExitEdit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'SAVE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.moduleName} · ${widget.platform} · ${widget.session.testCases.length} cases',
                    style: AppText.subheading,
                  ),
                  if (!AppConfig.isProduction) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Trace ID: ${widget.session.traceId}',
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.all(10),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Actual Result and Status are left empty — fill them during execution.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: MasterTable(
                  key: ValueKey(widget.session.testCases.hashCode),
                  testCases: widget.session.testCases,
                  isEditable: isEditable,
                  onCellEdit: _markUnsaved,
                  suiteId: widget.suiteId,
                  getOtherSuites: () async =>
                      AppDependencies.getHistoryUseCase.getAllSuites(),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'AI-generated content – please review and adjust before export.',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isEditable ? null : _openExport,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Export Options'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEditable
                          ? AppColors.textHint
                          : AppColors.accent,
                      foregroundColor: Colors.black,
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
  }
}
