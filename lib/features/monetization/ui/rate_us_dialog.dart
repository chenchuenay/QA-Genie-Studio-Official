import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';

void showRateUsDialog(BuildContext context) {
  showBlurredDialog(context, builder: (ctx) => const _RateUsDialogContent());
}

class _RateUsDialogContent extends StatelessWidget {
  const _RateUsDialogContent();

  Future<void> _openStore() async {
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.enaykumar.qagenie',
    ); // replace with your app ID
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
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
            const Icon(Icons.star_border, color: AppColors.accent, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Enjoying QA Genie?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Your feedback helps improve the app. Take a moment to rate it on the store.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Not Now",
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _openStore();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Rate Now",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
