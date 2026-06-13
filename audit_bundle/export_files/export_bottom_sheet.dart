import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/shared/dialogs/export_preview_dialog.dart';

class ExportBottomSheet extends StatefulWidget {
  final List<FinalizedTestCase> cases;
  final String moduleName;
  final String featureName;
  final Function(List<FinalizedTestCase> updatedCases) onSave;
  final Function(
    String type,
    List<FinalizedTestCase> updatedCases,
    String? adToken,
  )
  onExport;

  const ExportBottomSheet({
    super.key,
    required this.cases,
    required this.moduleName,
    required this.featureName,
    required this.onSave,
    required this.onExport,
  });

  @override
  State<ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<ExportBottomSheet> {
  void _openPreview(String type) async {
    await showDialog<List<FinalizedTestCase>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => ExportPreviewDialog(
        type: type,
        cases: widget.cases,
        moduleName: widget.moduleName,
        featureName: widget.featureName,
        onSave: (updated) {
          widget.onSave(updated);
          // Do NOT close the dialog here; the dialog itself will close after calling onSave
        },
        onShare: (updated, adToken) async {
          // Pass the share request to the parent without popping yet
          await widget.onExport(type, updated, adToken);
        },
      ),
    );
    // If the dialog returned updated cases (e.g., after save), we already called onSave above.
  }

  @override
  Widget build(BuildContext context) {
    // ... same UI as before
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Export Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _optionCard('Excel', Icons.table_chart, () => _openPreview('excel')),
          _optionCard(
            'Jira (CSV)',
            Icons.description,
            () => _openPreview('jira'),
          ),
          _optionCard('Xray (JSON)', Icons.code, () => _openPreview('xray')),
          _optionCard('PDF', Icons.picture_as_pdf, () => _openPreview('pdf')),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _optionCard(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.accent, size: 26),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
