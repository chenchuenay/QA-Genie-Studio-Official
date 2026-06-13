import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/theme/app_radius.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050505), Color(0xFF0A0A0A), Color(0xFF0D0D0D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with glow
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.1),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 84,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CONNECT TO INTERNET',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Generation and export require an internet connection.\nYour local suites, edits and reports remain available offline.',
                    style: AppText.body,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                _statusCard(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onRetry();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentLight],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: const Center(
                        child: Text(
                          'Retry Connection',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Continue Offline',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusRow('✓ Browse Suites', true),
          _statusRow('✓ Edit Test Cases', true),
          _statusRow('✓ Update Execution Status', true),
          _statusRow('✓ Save Local Changes', true),
          const SizedBox(height: 12),
          const Text(
            'Internet Required:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _statusRow('• Generate Test Cases', false),
          _statusRow('• Export Files', false),
          _statusRow('• Summary Export', false),
        ],
      ),
    );
  }

  Widget _statusRow(String text, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: enabled ? AppColors.success : AppColors.accent,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: enabled ? AppColors.textSecondary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
