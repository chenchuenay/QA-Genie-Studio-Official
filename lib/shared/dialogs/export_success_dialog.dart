import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/shared/dialogs/feedback_dialog.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/features/monetization/ui/rate_us_dialog.dart';

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
  bool _isSubmitting = false;
  bool _canShowRating = false;

  @override
  void initState() {
    super.initState();
    _initRating();
  }

  Future<void> _initRating() async {
    final canShow = await UsageManager.canShowStars();
    if (mounted) setState(() => _canShowRating = canShow);
  }

  Future<void> _handleRating(bool submit) async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    // Fire the rating write in background — no await on Submit flows
    // so the dialog transition is instant.
    final Future<void>? ratingWrite = _selectedRating > 0
        ? FunctionsService.call(
            functionName: 'trackRating',
            payload: {'rating': _selectedRating},
          ).then((_) {}).catchError((_) {})
        : null;

    if (submit && _selectedRating > 0 && _selectedRating <= 3) {
      // Low rating → FeedbackDialog → Report Issue screen
      final navigator = Navigator.of(context);
      navigator.pop();
      showBlurredDialog(
        navigator.context,
        builder: (ctx) => const FeedbackDialog(),
      );
      _isSubmitting = false;
      await ratingWrite; // wait in background, not blocking UI
      return;
    }

    if (submit && _selectedRating >= 4) {
      // High rating → RateUsDialog → Play Store
      final navigator = Navigator.of(context);
      navigator.pop();
      showRateUsDialog(navigator.context);
      _isSubmitting = false;
      await ratingWrite;
      return;
    }

    // Done button (no follow-up dialog)
    if (_selectedRating > 0) await ratingWrite;
    if (mounted) Navigator.of(context).pop();
    _isSubmitting = false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
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
              if (_canShowRating) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRating = index + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < _selectedRating ? Icons.star : Icons.star_border,
                          color: AppColors.accent,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => _handleRating(false),
                      child: const Text('Done', style: TextStyle(color: AppColors.textHint)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _selectedRating == 0 || _isSubmitting ? null : () => _handleRating(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Submit', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _isSubmitting ? null : () => _handleRating(false),
                  child: const Text('Done', style: TextStyle(color: AppColors.textHint)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
