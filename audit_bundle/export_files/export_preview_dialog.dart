import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/shared/ui/no_internet_screen.dart';
import 'package:qa_genie/shared/widgets/watch_ad_dialog.dart';
import 'package:qa_genie/features/monetization/ads/ad_units.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';
import 'package:qa_genie/features/monetization/ads/ad_service.dart';
import 'package:qa_genie/shared/dialogs/export_success_dialog.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/shared/widgets/animated_dots.dart';

class ExportPreviewDialog extends StatefulWidget {
  final String type; // 'excel', 'pdf', 'jira', 'xray'
  final List<FinalizedTestCase> cases;
  final String moduleName;
  final String featureName;
  final Function(List<FinalizedTestCase> updatedCases) onSave;
  final Function(List<FinalizedTestCase> updatedCases, String? adToken) onShare;

  const ExportPreviewDialog({
    super.key,
    required this.type,
    required this.cases,
    required this.moduleName,
    required this.featureName,
    required this.onSave,
    required this.onShare,
  });

  @override
  State<ExportPreviewDialog> createState() => _ExportPreviewDialogState();
}

class _ExportPreviewDialogState extends State<ExportPreviewDialog> {
  late List<List<String>> _data;
  late List<List<TextEditingController>> _controllers;
  bool _editing = false;
  int? _statusColumnIndex;
  int? _priorityColumnIndex;
  bool _savedSuccess = false;
  bool _isProcessing = false;
  bool _isSharing = false;

  static const List<double> _colWidths = [
    100,
    90,
    90,
    180,
    140,
    120,
    320,
    140,
    100,
    90,
    90,
  ];
  static const List<String> _statusOptions = [
    'Pass',
    'Fail',
    'Blocked',
    'Not Executed',
  ];
  static const List<String> _priorityOptions = ['High', 'Medium', 'Low'];

  String _normalizeStatus(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Not Executed';
    final lower = trimmed.toLowerCase();
    if (lower == 'pass') return 'Pass';
    if (lower == 'fail') return 'Fail';
    if (lower == 'blocked') return 'Blocked';
    return 'Not Executed';
  }

  String _normalizePriority(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Medium';
    final lower = trimmed.toLowerCase();
    if (lower == 'high') return 'High';
    if (lower == 'medium') return 'Medium';
    if (lower == 'low') return 'Low';
    return 'Medium';
  }

  @override
  void initState() {
    super.initState();
    _data = _getMappedData();
    _controllers = _data
        .map(
          (row) =>
              row.map((cell) => TextEditingController(text: cell)).toList(),
        )
        .toList();
    if (_data.isNotEmpty) {
      final headers = _data.first;
      _statusColumnIndex = headers.indexWhere(
        (h) => h.toLowerCase().contains('status'),
      );
      _priorityColumnIndex = headers.indexWhere(
        (h) => h.toLowerCase().contains('priority'),
      );
    }
  }

  @override
  void dispose() {
    for (final row in _controllers) for (final ctrl in row) ctrl.dispose();
    super.dispose();
  }

  List<List<String>> _getMappedData() {
    switch (widget.type) {
      case "excel":
        return ExportMapper.toExcel(
          widget.cases,
          moduleName: widget.moduleName,
          featureName: widget.featureName,
        );
      case "jira":
        return ExportMapper.toJira(
          widget.cases,
          featureName: widget.featureName,
        );
      case "xray":
        final jsonData = ExportMapper.toXray(
          widget.cases,
          moduleName: widget.moduleName,
          featureName: widget.featureName,
        );
        if (jsonData.isEmpty) return [];
        final keys = [
          "issueId",
          "summary",
          "testType",
          "description",
          "precondition",
          "priority",
          "status",
          "steps",
        ];
        final rows = <List<String>>[keys];
        for (final obj in jsonData) {
          final row = <String>[];
          for (final k in keys) {
            if (k == "steps") {
              dynamic stepsRaw = obj[k];
              List stepsList = [];
              if (stepsRaw is String)
                try {
                  stepsList = jsonDecode(stepsRaw);
                } catch (_) {}
              else if (stepsRaw is List)
                stepsList = stepsRaw;
              final buffer = StringBuffer();
              for (int i = 0; i < stepsList.length; i++) {
                final step = stepsList[i];
                buffer.writeln('${i + 1}. ${step['action'] ?? ''}');
                if ((step['data'] ?? '').isNotEmpty)
                  buffer.writeln('   Data: ${step['data']}');
                if ((step['expected'] ?? '').isNotEmpty)
                  buffer.writeln('   Expected: ${step['expected']}');
              }
              row.add(buffer.toString().trim());
            } else {
              row.add((obj[k] ?? '').toString());
            }
          }
          rows.add(row);
        }
        return rows;
      case "pdf":
        final pdfData = ExportMapper.toPdf(widget.cases);
        if (pdfData.isEmpty) return [];
        final keys = [
          "Test Case ID",
          "Title",
          "Preconditions",
          "Steps",
          "Test Data",
          "Expected Result",
          "Actual Result",
          "Status",
          "Priority",
        ];
        final rows = <List<String>>[keys];
        for (final obj in pdfData)
          rows.add(keys.map((k) => (obj[k] ?? '').toString()).toList());
        return rows;
      default:
        return [];
    }
  }

  List<List<String>> _collectEditedData() =>
      _controllers.map((row) => row.map((ctrl) => ctrl.text).toList()).toList();

  List<TestStep> _parseSteps(String stepsText) {
    final lines = stepsText.split('\n');
    final steps = <TestStep>[];
    String? currentAction;
    String? currentData;
    String? currentExpected;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final numberMatch = RegExp(r'^\d+\.').hasMatch(trimmed);
      if (numberMatch) {
        if (currentAction != null) {
          steps.add(
            TestStep(
              action: currentAction,
              data: currentData ?? '',
              expected: currentExpected ?? '',
            ),
          );
        }
        currentAction = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        currentData = null;
        currentExpected = null;
      } else if (trimmed.toLowerCase().startsWith('data:')) {
        currentData = trimmed.substring(5).trim();
      } else if (trimmed.toLowerCase().startsWith('expected:')) {
        currentExpected = trimmed.substring(8).trim();
      } else {
        if (currentAction != null) {
          currentAction += ' $trimmed';
        }
      }
    }
    if (currentAction != null) {
      steps.add(
        TestStep(
          action: currentAction,
          data: currentData ?? '',
          expected: currentExpected ?? '',
        ),
      );
    }
    return steps;
  }

  List<FinalizedTestCase> _updateOriginalCasesFromEditedData(
    List<List<String>> editedData,
  ) {
    if (editedData.length <= 1) return widget.cases;
    final headers = editedData.first;
    final updatedCases = <FinalizedTestCase>[];

    for (int rowIdx = 0; rowIdx < editedData.length - 1; rowIdx++) {
      if (rowIdx >= widget.cases.length) break;
      final original = widget.cases[rowIdx];
      final row = editedData[rowIdx + 1];
      var updated = original;

      for (
        int colIdx = 0;
        colIdx < headers.length && colIdx < row.length;
        colIdx++
      ) {
        final header = headers[colIdx].toLowerCase();
        final newValue = row[colIdx];
        if (newValue == _data[rowIdx + 1][colIdx]) continue;

        if (header.contains('id')) {
          updated = updated.copyWith(id: newValue);
        } else if (header.contains('title') || header.contains('summary')) {
          updated = updated.copyWith(title: newValue);
        } else if (header.contains('module')) {
          updated = updated.copyWith(module: newValue);
        } else if (header.contains('feature')) {
          updated = updated.copyWith(feature: newValue);
        } else if (header.contains('platform')) {
          updated = updated.copyWith(platform: newValue);
        } else if (header.contains('priority')) {
          updated = updated.copyWith(priority: _normalizePriority(newValue));
        } else if (header.contains('type') || header.contains('testtype')) {
          updated = updated.copyWith(type: newValue);
        } else if (header.contains('precondition') ||
            header.contains('preconditions') ||
            header.contains('description')) {
          final preList = newValue
              .split('\n')
              .expand((s) => s.split(';'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          updated = updated.copyWith(preconditions: preList);
        } else if (header.contains('step')) {
          final newSteps = _parseSteps(newValue);
          if (newSteps.isNotEmpty) {
            updated = updated.copyWith(steps: newSteps);
          }
        } else if (header.contains('test data') ||
            header.contains('testdata')) {
          updated = updated.copyWith(testData: newValue);
        } else if (header.contains('expected result')) {
          updated = updated.copyWith(expectedResult: newValue);
        } else if (header.contains('actual result') ||
            header.contains('actual')) {
          updated = updated.copyWith(actualResult: newValue);
        } else if (header.contains('status')) {
          updated = updated.copyWith(status: _normalizeStatus(newValue));
        }
      }

      if (original.dbId != null)
        updated = updated.copyWith(dbId: original.dbId);
      updatedCases.add(updated);
    }
    return updatedCases;
  }

  void _performSave() {
    final editedData = _collectEditedData();
    final updatedCases = _updateOriginalCasesFromEditedData(editedData);
    widget.onSave(updatedCases);
    setState(() {
      _data = editedData;
      _editing = false;
      _savedSuccess = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _savedSuccess = false);
    });
  }

  void _cancelEdit() {
    setState(() => _editing = false);
  }

  Future<void> _performExport() async {
    if (_isProcessing) return; 
    FocusManager.instance.primaryFocus?.unfocus(); // Force close keyboard instantly

    if (AppConfig.isProduction) {
      final hasInternet = await NetworkGuard.hasInternet();
      if (!hasInternet) {
        final shouldRetry = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => NoInternetScreen(onRetry: () => _performExport()),
          ),
        );
        if (shouldRetry != true) return;
        return;
      }
    }

    final shouldWatch = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WatchAdDialog(featureName: 'Export Test Cases'),
    );
    if (shouldWatch != true) return;

    setState(() => _isProcessing = true);

    final isPro = await UsageManager.isPro();
    String? adToken;
    if (!isPro) {
      adToken = await AdService.showRewardedAd(
        adUnitId: AdUnits.rewardedTcExport,
        context: context,
      );
      if (adToken == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
    }
    final editedData = _collectEditedData();
    final updatedCases = _updateOriginalCasesFromEditedData(editedData);

    // Before sharing sheet
    setState(() {
      _isSharing = true;
    });

    try {
      await widget.onShare(updatedCases, adToken);
      
      await FunctionsService.trackExport(
        summary: false,
        target: widget.type,
        extension: _extensionForType(widget.type),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSharing = false;
        });
        // Now pop the preview dialog
        Navigator.of(context, rootNavigator: true).pop();
        
        // Show success dialog
        showBlurredDialog(
          context,
          builder: (ctx) => ExportSuccessDialog(
            type: widget.type,
            moduleName: widget.moduleName,
          ),
        );
      }
    }
  }

  String _extensionForType(String type) {
    switch (type) {
      case 'excel':
        return 'xlsx';
      case 'jira':
        return 'csv';
      case 'xray':
        return 'json';
      case 'pdf':
        return 'pdf';
      default:
        return '';
    }
  }

  String _getButtonText() {
    switch (widget.type) {
      case 'excel':
        return 'Export XLSX';
      case 'pdf':
        return 'Export PDF';
      case 'jira':
        return 'Export CSV';
      case 'xray':
        return 'Export JSON';
      default:
        return 'Export';
    }
  }

  String _getTitle() {
    final capitalized = widget.type[0].toUpperCase() + widget.type.substring(1);
    return 'Export Preview • $capitalized';
  }

  @override
  Widget build(BuildContext context) {
    final headers = _data.isNotEmpty ? _data.first : <String>[];
    final rowCount = _controllers.length - 1;

    final headerRow = Row(
      children: List.generate(
        headers.length,
        (col) => Container(
          width: col < _colWidths.length ? _colWidths[col] : 100,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          color: AppColors.card,
          child: Text(
            headers[col],
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    final dataRows = <Widget>[];
    for (int rowIdx = 0; rowIdx < rowCount; rowIdx++) {
      final rowChildren = <Widget>[];
      for (int col = 0; col < headers.length; col++) {
        final w = col < _colWidths.length ? _colWidths[col] : 100.0;
        final isStatus =
            (_statusColumnIndex != null && col == _statusColumnIndex);
        final isPriority =
            (_priorityColumnIndex != null && col == _priorityColumnIndex);
        final controller = _controllers[rowIdx + 1][col];
        final cell = _editing
            ? (isStatus
                  ? Container(
                      width: w,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Center(
                        child: DropdownButton<String>(
                          value: _normalizeStatus(controller.text),
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          underline: const SizedBox(),
                          items: _statusOptions
                              .map(
                                (opt) => DropdownMenuItem(
                                  value: opt,
                                  child: Center(child: Text(opt)),
                                ),
                              )
                              .toList(),
                          onChanged: (newVal) {
                            if (newVal != null) {
                              controller.text = newVal;
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    )
                  : isPriority
                  ? Container(
                      width: w,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Center(
                        child: DropdownButton<String>(
                          value: _normalizePriority(controller.text),
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          underline: const SizedBox(),
                          items: _priorityOptions
                              .map(
                                (opt) => DropdownMenuItem(
                                  value: opt,
                                  child: Center(child: Text(opt)),
                                ),
                              )
                              .toList(),
                          onChanged: (newVal) {
                            if (newVal != null) {
                              controller.text = newVal;
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    )
                  : Container(
                      width: w,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: null,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ))
            : Container(
                width: w,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  controller.text,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              );
        rowChildren.add(cell);
      }
      dataRows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: rowChildren,
        ),
      );
      if (rowIdx < rowCount - 1) {
        dataRows.add(
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border.withOpacity(0.8),
          ),
        );
      }
    }

    final tableContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [headerRow, const SizedBox(height: 4), ...dataRows],
    );

    final dialogBody = Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _editing ? Icons.visibility : Icons.edit,
                    color: AppColors.accentLight,
                    size: 22,
                  ),
                  tooltip: _editing ? 'Done' : 'Edit',
                  onPressed: () => setState(() => _editing = !_editing),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                physics: (_isProcessing || _isSharing) ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  physics: (_isProcessing || _isSharing) ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  child: tableContent,
                ),
              ),
            ),
            if (_savedSuccess) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Changes saved',
                      style: TextStyle(color: AppColors.success, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (!_editing)
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isProcessing || _isSharing) ? null : _performExport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_isProcessing || _isSharing) 
                          ? AppColors.accent.withOpacity(0.5) 
                          : AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: (_isProcessing || _isSharing) 
                      ? const AnimatedDots(
                          label: '⚡ Processing',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        )
                      : Text(
                          _getButtonText(),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                  ),
                ),
              ),
            if (_editing)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _performSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: AdService.isAdLoading,
      builder: (context, isAdLoading, _) {
        final fullLock = _isProcessing || isAdLoading || _isSharing;
        
        Widget content = AbsorbPointer(
          absorbing: fullLock,
          child: dialogBody,
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
}
