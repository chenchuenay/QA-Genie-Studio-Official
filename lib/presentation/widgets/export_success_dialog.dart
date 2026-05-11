import 'package:flutter/material.dart';
import 'package:qa_app/app/theme/constants.dart';
import 'package:in_app_review/in_app_review.dart';

class ExportSuccessDialog extends StatelessWidget {
  final String type;
  final int count;
  final String moduleName;
  final VoidCallback onShareAgain;
  const ExportSuccessDialog({super.key, required this.type, required this.count, required this.moduleName, required this.onShareAgain});

  @override Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 60),
        const SizedBox(height: 16),
        const Text("Export Complete", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("$count test cases from \"$moduleName\" exported as $type.", style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(icon: const Icon(Icons.star, color: AppColors.warning), onPressed: () async { final review = InAppReview.instance; if (await review.isAvailable()) review.requestReview(); }))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Done"))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent), onPressed: () { Navigator.pop(context); onShareAgain(); }, child: const Text("Share Again"))),
        ]),
      ])),
    );
  }
}
