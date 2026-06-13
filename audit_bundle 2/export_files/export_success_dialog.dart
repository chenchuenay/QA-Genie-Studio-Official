import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/shared/dialogs/feedback_dialog.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';

class ExportSuccessDialog extends StatefulWidget {
  final String type;
  final String moduleName;

  const ExportSuccessDialog({
    super.key,
    required this.type,
    required this.moduleName,
  });

  @override
  State<ExportSuccessDialog> createState() => _ExportSuccessDialogState();
}

class _ExportSuccessDialogState extends State<ExportSuccessDialog> {
  int _selectedRating = 0;

  Future<void> _handleRating(bool submit) async {
    if (_selectedRating > 0) {
      await FunctionsService.call(
        functionName: 'trackRating',
        payload: {'rating': _selectedRating},
      );
    }

    if (submit) {
      if (_selectedRating >= 4) {
        final InAppReview inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          inAppReview.requestReview();
        }
      } else if (_selectedRating > 0 && _selectedRating <= 3) {
        if (!mounted) return;
        Navigator.of(context).pop();
        showBlurredDialog(
          context,
          builder: (ctx) => const FeedbackDialog(),
        );
        return;
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Complete',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Test cases from "${widget.moduleName}" exported as ${widget.type}.',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _selectedRating ? Icons.star : Icons.star_border,
                    color: AppColors.accent,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _selectedRating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _handleRating(false),
                  child: const Text('Done', style: TextStyle(color: AppColors.textHint)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _selectedRating == 0 ? null : () => _handleRating(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Submit', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
