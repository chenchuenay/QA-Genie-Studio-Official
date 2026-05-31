import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';

class ExportSuccessDialog extends StatelessWidget {
  final String type;
  final String moduleName;
  final VoidCallback onShareAgain;

  const ExportSuccessDialog({
    super.key,
    required this.type,
    required this.moduleName,
    required this.onShareAgain,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Export Complete',
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: Text(
        'Test cases from "$moduleName" exported as $type.',
        style: const TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // TODO: Open Play Store review page later
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Rate us', style: TextStyle(color: Colors.black)),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Done', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}