import 'package:flutter/material.dart';
import 'package:qa_app/app/theme/constants.dart';
import 'package:qa_app/domain/usecases/export_test_cases_use_case.dart';
import 'package:qa_app/domain/usecases/save_test_suite_use_case.dart';
import 'package:qa_app/domain/usecases/get_history_use_case.dart';
import 'package:qa_app/data/models/test_case_model.dart';
import 'package:qa_app/features/generation/ui/widgets/master_table.dart';
import 'package:qa_app/presentation/widgets/export_bottom_sheet.dart';
import 'package:qa_app/presentation/widgets/export_success_dialog.dart';
import 'package:qa_app/presentation/widgets/ad_dialog.dart';
import 'package:qa_app/features/summary/ui/summary_report_screen.dart';
import 'package:qa_app/features/monetization/logic/usage_manager.dart';

class PreviewScreen extends StatefulWidget {
  final List<TestCaseModel> testCases;
  final String moduleName, feature, platform;
  final int suiteId;
  const PreviewScreen({super.key, required this.testCases, required this.moduleName, required this.feature, required this.platform, required this.suiteId});
  @override State<PreviewScreen> createState() => _PreviewScreenState();
}
class _PreviewScreenState extends State<PreviewScreen>
    with WidgetsBindingObserver {
  bool isEditable = false;
  late List<TestCaseModel> originalData, workingData;
  final _exportUseCase = ExportTestCasesUseCase();
  final _saveUseCase = SaveTestSuiteUseCase();
  bool _hasUnsaved = false;

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    originalData = widget.testCases.map((e) => e.copy()).toList();
    workingData = widget.testCases.map((e) => e.copy()).toList();
  }
  void _markUnsaved() => setState(() => _hasUnsaved = true);
  Future<void> _autoSave() async {
    if (!_hasUnsaved) return;
    await _saveUseCase.update(suiteId: widget.suiteId, cases: workingData);
    setState(() { originalData = workingData.map((e) => e.copy()).toList(); _hasUnsaved = false; });
  }
  Future<bool> _onWillPop() async { await _autoSave(); return true; }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_hasUnsaved) {
        _autoSave();
      }
    }
  }

  void _toggleEdit() => setState(() => isEditable = !isEditable);
  void _undo() { setState(() { workingData = originalData.map((e) => e.copy()).toList(); _hasUnsaved = false; }); }
  Future<void> _saveAndExitEdit() async {
    await _autoSave();
    if (mounted) setState(() => isEditable = false);
  }

  Future<void> _export(String type) async {
    await _autoSave();
    final pro = await UsageManager.isPro();
    if (!pro) {
      final exportCount = await UsageManager.getExportCount();
      if (exportCount > 0) {
        final watched = await showDialog<bool>(context: context, builder: (_) => const AdDialog());
        if (watched != true) return;
      }
    }
    try {
      print('EXPORT: Starting $type with ${originalData.length} cases');
      print('EXPORT: actual cases count = ${originalData.length}');
      print('EXPORT: actual cases count = ${originalData.length}');
      await _exportUseCase.execute(type: type, cases: workingData, moduleName: widget.moduleName, featureName: widget.feature);
      await UsageManager.incrementExport();
      print('EXPORT: $type completed successfully');
      if (mounted) showDialog(context: context, builder: (_) => ExportSuccessDialog(type: type, count: workingData.length, moduleName: widget.moduleName, onShareAgain: () => _export(type)));
    } catch (e, stack) {
      print('EXPORT ERROR: $e');
      print('STACK: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export failed: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _openExport() async {
    await _autoSave();
    if (!mounted) return;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => ExportBottomSheet(cases: workingData, moduleName: widget.moduleName, featureName: widget.feature, onExport: (type, {editedData}) async { Navigator.pop(context); await _export(type); }));
  }

  void _openSummary() async { await _autoSave(); if (!mounted) return; Navigator.push(context, MaterialPageRoute(builder: (_) => SummaryReportScreen(testCases: workingData, moduleName: widget.moduleName, feature: widget.feature, platform: widget.platform, suiteId: widget.suiteId))); }

  @override Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 8.0;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(children: [
          Container(padding: EdgeInsets.fromLTRB(4, topPadding, 16, 12), decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.surface, AppColors.background], begin: Alignment.topCenter, end: Alignment.bottomCenter)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () async { if (await _onWillPop()) Navigator.pop(context); }),
              const Spacer(),
              if (!isEditable) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton.icon(
                    onPressed: _openSummary,
                    icon: const Icon(Icons.description, size: 16, color: AppColors.accent),
                    label: const Text("Summary Report", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 11)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accent, width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), backgroundColor: AppColors.accent.withOpacity(0.08), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  ),
                ),
                OutlinedButton(
                  onPressed: _toggleEdit,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  child: const Text("EDIT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
              if (isEditable) ...[
                TextButton(onPressed: _undo, style: TextButton.styleFrom(foregroundColor: AppColors.error, padding: const EdgeInsets.symmetric(horizontal: 8)), child: const Text("UNDO", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                const SizedBox(width: 4),
                ElevatedButton(onPressed: _saveAndExitEdit, style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ]),
            const SizedBox(height: 12),
            Text("${widget.moduleName} · ${widget.platform} · ${originalData.length} cases", style: AppText.subheading),
          ])),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Actual Result and Status are left empty — fill them during execution. Accurate reporting starts with what you record.",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: MasterTable(testCases: workingData, originalData: originalData, isEditable: isEditable, onCellEdit: _markUnsaved, suiteId: widget.suiteId, getOtherSuites: () async { final svc = GetHistoryUseCase(); return await svc.execute(); }))),
          const Padding(padding: EdgeInsets.only(bottom: 4), child: Text("AI‑generated content – please review and adjust before export.", style: TextStyle(color: AppColors.textHint, fontSize: 10, fontStyle: FontStyle.italic), textAlign: TextAlign.center)),
          SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16,4,16,16), child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _openExport, icon: const Icon(Icons.file_download), label: const Text("Export Options"), style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))))),
        ]),
      ),
    );
  }
}
