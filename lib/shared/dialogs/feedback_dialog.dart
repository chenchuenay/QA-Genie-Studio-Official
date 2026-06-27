import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/features/support/ui/report_issue_screen.dart';

class FeedbackDialog extends StatelessWidget {
  const FeedbackDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isGuest = AuthService.isGuest;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Send feedback',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isGuest
                  ? 'Sign in with Google to share your feedback.\nYour input helps make QA Genie better.'
                  : 'Care to share feedback?\nWould you like to report the issue?',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Not Now', style: TextStyle(color: AppColors.textHint)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (isGuest) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReportIssueScreen(screen: 'Feedback'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isGuest ? AppColors.textHint : AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isGuest ? 'OK' : 'Share', style: const TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
