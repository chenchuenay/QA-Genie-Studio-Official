import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/constants.dart';
import 'package:qa_genie/presentation/widgets/export_preview_dialog.dart';
import 'package:qa_genie/data/models/test_case_model.dart';

class ExportBottomSheet extends StatelessWidget {
  final List<TestCaseModel> cases;
  final String moduleName;
  final String featureName;
  final Function(String type, {List<List<String>>? editedData}) onExport;

  const ExportBottomSheet({super.key, required this.cases, required this.moduleName, required this.featureName, required this.onExport});

  @override Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text("Export Options", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3, physics: const NeverScrollableScrollPhysics(),
            children: [
              _card("Excel", Icons.table_chart, AppColors.success, ".xlsx", () => _showPreview(context, "excel")),
              _card("Jira", Icons.bug_report, AppColors.blue, ".csv", () => _showPreview(context, "jira")),
              _card("Xray", Icons.analytics, AppColors.orange, ".json", () => _showPreview(context, "xray")),
              _card("PDF (Print & Share)", Icons.picture_as_pdf, Colors.redAccent, ".pdf", () => _showPreview(context, "pdf")),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Exports are formatted per tool specification. No data leaves this device.", style: TextStyle(color: AppColors.textHint, fontSize: 11), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  void _showPreview(BuildContext context, String type) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: ExportPreviewDialog(
          type: type, cases: cases, moduleName: moduleName, featureName: featureName,
          onConfirm: (editedData) { onExport(type, editedData: editedData); },
        ),
      ),
    );
  }

  Widget _card(String label, IconData icon, Color color, String extension, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 24), const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(extension, style: const TextStyle(color: AppColors.textHint, fontSize: 9, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
