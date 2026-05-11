import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qa_app/app/theme/constants.dart';
import 'package:qa_app/core/utils/dialog_utils.dart';

class BugReportButton extends StatelessWidget {
  const BugReportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bug_report, color: Colors.white70),
      tooltip: 'Report an issue',
      onPressed: () => showBlurredDialog(context, builder: (_) => _BugReportForm()),
    );
  }
}

class _BugReportForm extends StatefulWidget {
  @override State<_BugReportForm> createState() => _BugReportFormState();
}
class _BugReportFormState extends State<_BugReportForm> {
  String? type = 'UI';
  String? area = 'Generate';
  final descCtrl = TextEditingController();
  final stepsCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override void dispose() { descCtrl.dispose(); stepsCtrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text("Report an Issue", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            // Inactive notice
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                "Feature coming soon – not connected to backend yet.",
                style: TextStyle(color: AppColors.textHint, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabeledDropdown(label: "Type", value: type, hintText: "Select type", items: ['UI', 'Crash', 'Others'], onChanged: (v) => setState(() => type = v)),
            const SizedBox(height: 12),
            _buildLabeledDropdown(label: "Area", value: area, hintText: "Select area", items: ['Generate', 'Suites', 'Others'], onChanged: (v) => setState(() => area = v)),
            const SizedBox(height: 12),
            TextFormField(controller: descCtrl, maxLength: 100, maxLines: 2, style: const TextStyle(color: Colors.white), validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter a description." : null,
              decoration: InputDecoration(labelText: "Brief description", labelStyle: const TextStyle(color: AppColors.textSecondary), hintStyle: const TextStyle(color: AppColors.textHint), fillColor: AppColors.card, filled: true, counterStyle: const TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)), errorStyle: const TextStyle(color: AppColors.error)),
            ),
            const SizedBox(height: 12),
            TextField(controller: stepsCtrl, maxLines: 2, maxLength: 100, style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: "Steps to reproduce (optional)", labelStyle: const TextStyle(color: AppColors.textSecondary), hintStyle: const TextStyle(color: AppColors.textHint), fillColor: AppColors.card, filled: true, counterStyle: const TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent))),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary))),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () { if (formKey.currentState!.validate()) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report submitted, thank you!"), backgroundColor: AppColors.success)); } },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Report", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildLabeledDropdown({required String label, required String? value, required String hintText, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (context, constraints) {
          return PopupMenuButton<String>(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, maxWidth: constraints.maxWidth),
            offset: const Offset(0, 38), color: AppColors.card, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(value ?? hintText, style: TextStyle(color: value != null ? Colors.white : AppColors.textHint, fontSize: 14)), const Icon(Icons.arrow_drop_down, color: Colors.white70)]),
            ),
            onSelected: onChanged,
            itemBuilder: (_) => items.map((e) => PopupMenuItem<String>(value: e, height: 40, child: Center(child: Text(e, style: const TextStyle(color: Colors.white))))).toList(),
          );
        }),
      ]),
    );
  }
}
