import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:qa_genie/engine/risk/risk_scorer.dart';

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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static bool _guidelinesShownThisLaunch = false;

  final ExportTestCasesUseCase _exportUseCase = ExportTestCasesUseCase();
  final SaveSuiteUseCase _saveUseCase = AppDependencies.saveSuiteUseCase;

  Timer? _debounceTimer;
  bool isEditable = false;
  bool _hasUnsaved = false;
  bool _hasDuplicateIds = false;
  bool _isExporting = false;
  List<FinalizedTestCase>? _backupCases;
  bool _selectionMode = false;
  final Set<int> _selectedIndices = {};

  bool _riskMode = false;
  List<FinalizedTestCase>? _originalOrder;
  Map<String, int> _riskScores = {};

  bool _guidelinesDismissed = false;
  bool _helpTappedThisSession = false;
  Timer? _guidelinesTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 0.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkGuidelines();
  }

  @override
  void dispose() {
    _guidelinesTimer?.cancel();
    _debounceTimer?.cancel();
    _pulseController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _forceSave();
  }

  Future<void> _checkGuidelines() async {
    if (_guidelinesShownThisLaunch) return;
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('suite_preview_guidelines_shown') ?? false;
    if (mounted) {
      setState(() => _guidelinesDismissed = dismissed);
      if (!dismissed) {
        _guidelinesTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) _showGuidelinesDialog();
        });
      }
    }
  }

  bool get _shouldPulseHelp => _guidelinesDismissed && !_helpTappedThisSession;

  Future<void> _showGuidelinesDialog({bool showDontShowAgain = true}) async {
    bool dontShowAgain = false;
    final scrollController = ScrollController();
    if (showDontShowAgain) {
      Future.delayed(const Duration(seconds: 2), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    }
    await showBlurredDialog(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Suite Preview — Features Guide',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _guideSection(
                  '📋',
                  'Summary Report',
                  'View execution stats, pass/fail counts, and export a formal PDF report.\nTap to open whenever ready.',
                ),
                const SizedBox(height: 12),
                _guideSection(
                  '🛡️',
                  'Risk Sort',
                  'Sort cases by risk level automatically. Security + Negative + High Priority cases rise to the top.\nGreat for deciding what to test first. Tap again to restore original order.',
                ),
                const SizedBox(height: 12),
                _guideSection(
                  '✏️',
                  'Edit Mode',
                  'Modify case titles, steps, priorities, and more inline. Tap Save to persist changes.\nRisk Sort turns off during editing.',
                ),
                const SizedBox(height: 12),
                _guideSection(
                  '👆',
                  'Long-Press a Row',
                  'Select multiple cases to Copy, Move, or Delete as a batch.\nUseful for grouping high-risk cases into a new suite for focused export.',
                ),
                const SizedBox(height: 12),
                _guideSection(
                  '📥',
                  'Export Options',
                  'Export cases as Excel, PDF, Jira CSV, or Xray JSON.\nAvailable when not in Edit, Selection, or Risk Sort mode.',
                ),
                const SizedBox(height: 12),
                _guideSection(
                  'ℹ️',
                  'Status Banner',
                  '"Actual Result" and "Status" are blank by design — fill them during execution.',
                ),
                if (showDontShowAgain) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: dontShowAgain,
                        onChanged: (v) =>
                            setInnerState(() => dontShowAgain = v ?? false),
                        fillColor: WidgetStateProperty.resolveWith(
                          (_) => AppColors.accent,
                        ),
                        checkColor: Colors.black,
                        side: const BorderSide(color: AppColors.textHint),
                      ),
                      const Text(
                        "Don't show this again",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _guidelinesShownThisLaunch = true;
                if (dontShowAgain) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('suite_preview_guidelines_shown', true);
                  if (mounted) setState(() => _guidelinesDismissed = true);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'Got it',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideSection(String emoji, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
    if (isEditable) return false;
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
      if (_riskMode) _toggleRiskMode();
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

  String _reId(String originalId, int newIndex) {
    final match = RegExp(r'^(.+?)(\d+)$').firstMatch(originalId);
    if (match == null) return '${originalId}${newIndex.toString().padLeft(3, '0')}';
    final prefix = match.group(1)!;
    final width = match.group(2)!.length;
    return '${prefix}${newIndex.toString().padLeft(width, '0')}';
  }

  void _toggleRiskMode() {
    if (isEditable) {
      _saveAndExitEdit();
    }
    setState(() {
      if (!_riskMode) {
        _originalOrder = List.from(widget.session.testCases);
        _riskScores = RiskScorer.score(widget.session.testCases);
        widget.session.testCases.sort(
          (a, b) => (_riskScores[b.id] ?? 0).compareTo(_riskScores[a.id] ?? 0),
        );
        _riskMode = true;
      } else {
        if (_originalOrder != null) {
          widget.session.testCases
            ..clear()
            ..addAll(_originalOrder!);
          _originalOrder = null;
        }
        _riskMode = false;
      }
    });
  }

  Future<void> _export(
    String type,
    String? adToken, {
    bool hideEmptyColumns = false,
    bool showSuccess = true,
  }) async {
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
        hideEmptyColumns: hideEmptyColumns,
      );
      if (!mounted) return;
      AccountScreen.markForRefresh();
      if (showSuccess) {
        showBlurredDialog(
          context,
          builder: (_) =>
              ExportSuccessDialog(type: type, moduleName: widget.moduleName),
        );
      }
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
      rethrow;
    } finally {
      _isExporting = false;
    }
  }

  Future<void> _openExport() async {
    _guidelinesTimer?.cancel();
    if (_riskMode) {
      await showBlurredDialog(
        context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Risk Sort Active',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Export is disabled while Risk Sort is active.\n\n'
            'To export grouped by risk level:\n'
            '1. Long-press high-risk cases to select\n'
            '2. Tap Copy/Move to another suite\n'
            '3. Export from that suite',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'OK',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      );
      return;
    }
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
            showBlurredDialog(
              context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Saved',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Changes saved.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            );
            setState(() {});
          }
        },
        onExport: (type, updated, adToken, {hideEmptyColumns = false}) async {
          widget.session.testCases = List.from(updated);
          await _saveUseCase.saveSuite(
            suiteId: widget.suiteId,
            cases: widget.session.testCases,
          );
          // Trigger the export — success dialog is handled by the preview dialog
          await _export(
            type,
            adToken,
            hideEmptyColumns: hideEmptyColumns,
            showSuccess: false,
          );
          // Finally pop the bottom sheet
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _openSummary() async {
    _guidelinesTimer?.cancel();
    await _autoSave();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryReportScreen(
          session: GenerationSession(
            traceId: widget.session.traceId,
            testCases: widget.session.testCases
                .map((c) => c.copyWith())
                .toList(),
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
    final targetSuiteId = await showBlurredDialog<int>(
      context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Copy to Suite',
          style: TextStyle(color: Colors.white),
        ),
        content: ListView.builder(
          shrinkWrap: true,
          itemCount: suites.length,
          itemBuilder: (_, i) {
            final s = suites[i];
            final sid = (s['id'] as num?)?.toInt() ?? 0;
            return ListTile(
              title: Text(
                '${s['moduleName']} · ${s['feature']}',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx, sid),
            );
          },
        ),
      ),
    );
    if (targetSuiteId == null) return;
    final existing = await DatabaseService.getTestCasesForSuite(targetSuiteId);
    final casesToCopy = <FinalizedTestCase>[];
    for (var j = 0; j < _selectedIndices.length; j++) {
      final tc = widget.session.testCases[_selectedIndices.elementAt(j)];
      casesToCopy.add(tc.copyWith(
        id: _reId(tc.id, existing.length + j + 1),
        dbId: null,
      ));
    }
    await DatabaseService.insertTestCases(
      suiteId: targetSuiteId,
      cases: casesToCopy,
    );
    _exitSelectionMode();
    if (mounted) {
      showBlurredDialog(
        context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Copied', style: TextStyle(color: Colors.white)),
          content: Text(
            'Copied ${casesToCopy.length} case(s).',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'OK',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _batchMove() async {
    final suites = await AppDependencies.getHistoryUseCase.getAllSuites();
    if (!mounted) return;
    final targetSuiteId = await showBlurredDialog<int>(
      context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Move to Suite',
          style: TextStyle(color: Colors.white),
        ),
        content: ListView.builder(
          shrinkWrap: true,
          itemCount: suites.length,
          itemBuilder: (_, i) {
            final s = suites[i];
            final sid = (s['id'] as num?)?.toInt() ?? 0;
            if (sid == widget.suiteId) return const SizedBox.shrink();
            return ListTile(
              title: Text(
                '${s['moduleName']} · ${s['feature']}',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx, sid),
            );
          },
        ),
      ),
    );
    if (targetSuiteId == null) return;
    final existing = await DatabaseService.getTestCasesForSuite(targetSuiteId);
    final indices = List.from(_selectedIndices)..sort((a, b) => b.compareTo(a));
    final originalCases = indices
        .map((i) => widget.session.testCases[i])
        .toList();
    final deleteIds = originalCases
        .map((tc) => tc.dbId)
        .whereType<int>()
        .toList();
    final casesToMove = originalCases.asMap().entries.map((entry) {
      final tc = entry.value;
      return tc.copyWith(
        id: _reId(tc.id, existing.length + entry.key + 1),
        dbId: null,
      );
    }).toList();
    await DatabaseService.insertTestCases(
      suiteId: targetSuiteId,
      cases: casesToMove,
    );
    await DatabaseService.markSuiteDirty(targetSuiteId);
    if (deleteIds.isNotEmpty)
      await DatabaseService.batchDeleteTestCases(deleteIds);
    for (final i in indices) {
      widget.session.testCases.removeAt(i);
    }
    _exitSelectionMode();
    if (mounted) {
      setState(() {});
      showBlurredDialog(
        context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Moved', style: TextStyle(color: Colors.white)),
          content: Text(
            'Moved ${casesToMove.length} case(s).',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'OK',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _batchDelete() async {
    final count = _selectedIndices.length;
    final confirmed = await showBlurredDialog<bool>(
      context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Cases?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete $count selected case(s)? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final indices = List.from(_selectedIndices)..sort((a, b) => b.compareTo(a));
    final deleteIds = indices
        .map((i) => widget.session.testCases[i].dbId)
        .whereType<int>()
        .toList();
    if (deleteIds.isNotEmpty)
      await DatabaseService.batchDeleteTestCases(deleteIds);
    for (final i in indices) {
      widget.session.testCases.removeAt(i);
    }
    _exitSelectionMode();
    if (mounted) {
      setState(() {});
      showBlurredDialog(
        context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Deleted', style: TextStyle(color: Colors.white)),
          content: Text(
            'Deleted $count case(s).',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'OK',
                style: TextStyle(color: AppColors.accent),
              ),
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
                          if (isEditable) return;
                          if (_selectionMode) {
                            _exitSelectionMode();
                          } else if (await _onWillPop() && mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectionMode
                            ? '${_selectedIndices.length} selected'
                            : 'Suite',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_selectionMode) ...[
                                _selIcon(Icons.content_copy, 'Copy', _batchCopy),
                                const SizedBox(width: 2),
                                _selIcon(Icons.drive_file_move, 'Move', _batchMove),
                                const SizedBox(width: 2),
                                _selIcon(
                                  Icons.delete,
                                  'Delete',
                                  _batchDelete,
                                  isDestructive: true,
                                ),
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
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: _toggleRiskMode,
                                  icon: _riskMode
                                      ? const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('🛡️', style: TextStyle(fontSize: 18)),
                                            Text(
                                              'ON',
                                              style: TextStyle(
                                                color: AppColors.accent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 9,
                                                height: 1,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          '🛡️',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                  tooltip: 'Risk Sort',
                                  style: IconButton.styleFrom(
                                    backgroundColor: _riskMode
                                        ? AppColors.accent.withOpacity(0.2)
                                        : Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.only(
                                      right: 1,
                                      left: 4,
                                      top: 2,
                                      bottom: 2,
                                    ),
                                    minimumSize: const Size(24, 24),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    final pulse = _shouldPulseHelp
                                        ? _pulseAnimation.value
                                        : 0.0;
                                    return Transform.scale(
                                      scale: 1.0 + pulse,
                                      child: IconButton(
                                        onPressed: () {
                                          _helpTappedThisSession = true;
                                          _showGuidelinesDialog(
                                            showDontShowAgain: false,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.help_outline,
                                          color: Colors.white70,
                                          size: 19,
                                        ),
                                        tooltip: 'Help',
                                        style: IconButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(30, 30),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                OutlinedButton(
                                  onPressed: _toggleEdit,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: AppColors.border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 2,
                                    ),
                                    minimumSize: const Size(30, 30),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text(
                                    'EDIT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
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
                                  onPressed: _hasDuplicateIds
                                      ? () => showBlurredDialog(context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: AppColors.surface,
                                            title: const Text('Duplicate IDs',
                                                style: TextStyle(color: Colors.white)),
                                            content: const Text(
                                              'Fix duplicate IDs before saving.',
                                              style: TextStyle(color: AppColors.textSecondary),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('OK',
                                                    style: TextStyle(color: AppColors.accent)),
                                              ),
                                            ],
                                          ))
                                      : _saveAndExitEdit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _hasDuplicateIds
                                        ? AppColors.error.withOpacity(0.3)
                                        : AppColors.success,
                                    foregroundColor:
                                        _hasDuplicateIds ? Colors.white38 : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.moduleName} · ${widget.platform} · ${widget.session.testCases.length} cases',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppText.subheading,
                  ),
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
                  riskMode: _riskMode,
                  riskScores: _riskScores,
                  onDuplicateChange: (hasDup) {
                    if (mounted) setState(() => _hasDuplicateIds = hasDup);
                  },
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
                  onPressed: (isEditable || _riskMode) ? null : _openExport,
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export Options'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isEditable || _riskMode)
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

  Widget _selIcon(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
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
          backgroundColor: isDestructive
              ? Colors.red.withOpacity(0.15)
              : Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
