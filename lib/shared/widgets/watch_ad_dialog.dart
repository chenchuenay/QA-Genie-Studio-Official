import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_radius.dart';
import 'package:qa_genie/app/theme/app_spacing.dart';

class WatchAdDialog extends StatelessWidget {
  final String featureName;

  const WatchAdDialog({super.key, required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: AppColors.modal,
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 30,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                featureName,
                style: AppText.cardTitle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    '$featureName is supported by a short ad to help keep QA Genie free and growing.',
                    style: AppText.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: const Text(
                        'No Thanks',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: const Text('Watch Ad', style: AppText.button),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
