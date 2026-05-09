import 'package:flutter/material.dart';
import 'package:qa_app/core/theme/constants.dart';

class AdDialog extends StatelessWidget {
  const AdDialog({super.key});

  @override Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.ad_units, color: AppColors.warning, size: 50),
        const SizedBox(height: 10),
        const Text("Unlock this feature", style: TextStyle(color: Colors.white, fontSize: 18)),
        const SizedBox(height: 8),
        const Text("Watch a short ad to continue.", style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: const Text("Watch Ad (Mock)", style: TextStyle(color: Colors.black)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("No thanks", style: TextStyle(color: AppColors.textHint)),
        ),
      ])),
    );
  }
}
