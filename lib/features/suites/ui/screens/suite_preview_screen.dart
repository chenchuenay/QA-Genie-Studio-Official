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
import 'package:qa_genie/features/account/ui/account_screen.dart';
import 'package:qa_genie/features/summary/ui/summary_report_screen.dart';
import 'package:qa_genie/domain/usecases/export_test_cases_use_case.dart';
import 'package:qa_genie/features/generation/ui/widgets/master_table.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/core/database/database_service.dart';

class SuitePreviewScreen extends StatefulWidget {
  final GenerationSession session;
  final String moduleName;
  final String feature;
  final String platform;
  final int suiteId;

  const SuitePreviewScreen({
    super.key,
    required this.session,
    required this.moduleName,
    required this.feature,
    required this.platform,
    required this.suiteId,
  });

  @override
  State<SuitePreviewScreen> createState() => _SuitePreviewScreenState();
}

class _SuitePreviewScreenState extends State<SuitePreviewScreen>
    with WidgetsBindingObserver {
  final ExportTestCasesUseCase _exportUseCase = ExportTestCasesUseCase();
  final SaveSuiteUseCase _saveUseCase = AppDependencies.saveSuiteUseCase;

  Timer? _debounceTimer;
  bool isEditable = false;
  bool _hasUnsaved = false;
  bool _isExporting = false;
  List<FinalizedTestCase>? _backupCases;
  bool _selectionMode = false;
  final Set<int> _selectedIndices = {};

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
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _autoSave();
    });
  }

  void _toggleEdit() {
    if (!isEditable) {
      _backupCases = widget.session.testCases
          .map((tc) => tc.copyWith())
          .toList();
    }
    setState(() => isEditable = !isEditable);
  }

  Future<void> _undoAndExitEdit() async {
    if (_backupCases != null) {
      final saved = _backupCases!;
      widget.session.testCases.clear();
      widget.session.testCases.addAll(saved);
      // Revert DB if auto-save already persisted edits
      if (!_hasUnsaved) {
        await _saveUseCase.saveSuite(suiteId: widget.suiteId, cases: saved);
      }
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
        screen: 'SuitePreviewScreen',
        stage: ErrorStage.unknown,
        severity: ErrorSeverity.error,
        memberMessage: 'Save failed. Please try again.',
        error: e,
        stack: stack,
      );
    }
  }

  Future<void> _export(String type, String? adToken) async {
    if (_isExporting) return;
    _isExporting = true;
    try {
      await _autoSave();
      await _exportUseCase.execute(
        type: type,
        cases: widget.session.testCases,
        moduleName: widget.moduleName,
        featureName: widget.feature,
        adToken: adToken,
      );
      if (!mounted) return;
      AccountScreen.markForRefresh();
      showBlurredDialog(context,
        builder: (_) =>
            ExportSuccessDialog(type: type, moduleName: widget.moduleName),
      );
    } catch (e, stackTrace) {
      UiErrorService.logAndShow(
        context: context,
        source: ErrorSource.exportEngine,
        screen: 'SuitePreviewScreen',
        stage: ErrorStage.export,
        severity: ErrorSeverity.error,
        memberMessage: 'Export failed. Please try again.',
        error: e,
        stack: stackTrace,
      );
    } finally {
      _isExporting = false;
    }
  }

  Future<void> _openExport() async {
    await _autoSave();
    if (!mounted) return;
    await showBlurredDialog<List<FinalizedTestCase>>(
      context,
      alignment: Alignment.bottomCenter,
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
            showBlurredDialog(context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('Saved', style: TextStyle(color: Colors.white)),
                content: const Text('Changes saved.', style: TextStyle(color: AppColors.textSecondary)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK', style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
            );
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
          session: GenerationSession(
            traceId: widget.session.traceId,
            testCases: widget.session.testCases.map((c) => c.copyWith()).toList(),
            auditReport: widget.session.auditReport,
          ),
          moduleName: widget.moduleName,
          feature: widget.feature,
          platform: widget.platform,
          suiteId: widget.suiteId,
        ),
      ),
    );
  }

  void _onSelectionChanged(Set<int> indices) {
    setState(() {
      _selectedIndices.clear();
      _selectedIndices.addAll(indices);
      if (_selectedIndices.isNotEmpty && !_selectionMode) {
        _selectionMode = true;
        if (isEditable) {
          _saveAndExitEdit();
        }
      } else if (_selectedIndices.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIndices.clear();
    });
  }

  Future<void> _batchCopy() async {
    final suites = await AppDependencies.getHistoryUseCase.getAllSuites();
    if (!mounted) return;
    final targetSuiteId = await showBlurredDialog<int>(context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Copy to Suite', style: TextStyle(color: Colors.white)),
        content: ListView.builder(
          shrinkWrap: true,
          itemCount: suites.length,
          itemBuilder: (_, i) {
            final s = suites[i];
            final sid = (s['id'] as num?)?.toInt() ?? 0;
            return ListTile(
              title: Text('${s['moduleName']} · ${s['feature']}', style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, sid),
            );
          },
        ),
      ),
    );
    if (targetSuiteId == null) return;
    final casesToCopy = _selectedIndices.map((i) {
      final tc = widget.session.testCases[i];
      return tc.copyWith(id: '${tc.id}_copy', dbId: null);
    }).toList();
    await DatabaseService.insertTestCases(suiteId: targetSuiteId, cases: casesToCopy);
    _exitSelectionMode();
    if (mounted) {
      showBlurredDialog(context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Copied', style: TextStyle(color: Colors.white)),
          content: Text('Copied ${casesToCopy.length} case(s).', style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _batchMove() async {
    final suites = await AppDependencies.getHistoryUseCase.getAllSuites();
    if (!mounted) return;
    final targetSuiteId = await showBlurredDialog<int>(context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Move to Suite', style: TextStyle(color: Colors.white)),
        content: ListView.builder(
          shrinkWrap: true,
          itemCount: suites.length,
          itemBuilder: (_, i) {
            final s = suites[i];
            final sid = (s['id'] as num?)?.toInt() ?? 0;
            if (sid == widget.suiteId) return const SizedBox.shrink();
            return ListTile(
              title: Text('${s['moduleName']} · ${s['feature']}', style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, sid),
            );
          },
        ),
      ),
    );
    if (targetSuiteId == null) return;
    final indices = List.from(_selectedIndices)..sort((a, b) => b.compareTo(a));
    final casesToMove = indices.map((i) => widget.session.testCases[i]).toList();
    final deleteIds = casesToMove.map((tc) => tc.dbId).whereType<int>().toList();
    await DatabaseService.insertTestCases(suiteId: targetSuiteId, cases: casesToMove);
    await DatabaseService.markSuiteDirty(targetSuiteId);
    if (deleteIds.isNotEmpty) await DatabaseService.batchDeleteTestCases(deleteIds);
    for (final i in indices) {
      widget.session.testCases.removeAt(i);
    }
    _exitSelectionMode();
    if (mounted) {
      setState(() {});
      showBlurredDialog(context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Moved', style: TextStyle(color: Colors.white)),
          content: Text('Moved ${casesToMove.length} case(s).', style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _batchDelete() async {
    final count = _selectedIndices.length;
    final confirmed = await showBlurredDialog<bool>(context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Cases?', style: TextStyle(color: Colors.white)),
        content: Text('Delete $count selected case(s)? This cannot be undone.', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    final indices = List.from(_selectedIndices)..sort((a, b) => b.compareTo(a));
    final deleteIds = indices.map((i) => widget.session.testCases[i].dbId).whereType<int>().toList();
    if (deleteIds.isNotEmpty) await DatabaseService.batchDeleteTestCases(deleteIds);
    for (final i in indices) {
      widget.session.testCases.removeAt(i);
    }
    _exitSelectionMode();
    if (mounted) {
      setState(() {});
      showBlurredDialog(context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Deleted', style: TextStyle(color: Colors.white)),
          content: Text('Deleted $count case(s).', style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );
    }
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
                          if (_selectionMode) {
                            _exitSelectionMode();
                          } else if (await _onWillPop() && mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectionMode ? '${_selectedIndices.length} selected' : 'Suite',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_selectionMode) ...[
                        _selIcon(Icons.content_copy, 'Copy', _batchCopy),
                        const SizedBox(width: 2),
                        _selIcon(Icons.drive_file_move, 'Move', _batchMove),
                        const SizedBox(width: 2),
                        _selIcon(Icons.delete, 'Delete', _batchDelete, isDestructive: true),
                        const SizedBox(width: 6),
                        _selIcon(Icons.close, 'Done', _exitSelectionMode),
                      ] else if (!isEditable) ...[
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
                        const SizedBox(width: 12),
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
                          onPressed: () => _undoAndExitEdit(),
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
                        'Actual Result and Status are left empty by design — intended to be recorded during execution.',
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
                  selectionMode: _selectionMode,
                  selectedIndices: _selectedIndices,
                  onSelectionChanged: _onSelectionChanged,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.zero,
              child: Text(
                'Hybrid-logic generation orchestrated. Please review/adjust before export.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9E9E9E), // Colors.grey[500] hex
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          ],
        ),
      ),
    );
  }

  Widget _selIcon(IconData icon, String tooltip, VoidCallback onPressed, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.red.shade300 : Colors.white70;
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        color: color,
        tooltip: tooltip,
        splashRadius: 18,
        style: IconButton.styleFrom(
          backgroundColor: isDestructive ? Colors.red.withOpacity(0.15) : Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
