import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';

class AdService {
  static int _exportCount = 0;
  static bool _isAdShowing = false;

  /// Shows a rewarded ad dialog.
  /// Returns true if the user watched the ad and received the reward.
  static Future<bool> showRewardedAd({
    required String adUnitId,
    required VoidCallback onRewarded,
    required BuildContext context,
  }) async {
    if (_isAdShowing) return false;
    _isAdShowing = true;

    final completer = Completer<bool>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RewardedAdDialog(
        onWatchPressed: () async {
          // Close the dialog first
          Navigator.of(ctx).pop();
          bool rewarded = false;

          if (!AppConfig.isProduction) {
            // DEV: Instant reward
            rewarded = true;
            onRewarded();
          } else {
            // PROD: Real rewarded ad flow (placeholder)
            // In production, integrate with actual AdMob rewarded ad.
            // For now, simulate a 1.5s ad and then reward.
            try {
              await Future.delayed(const Duration(seconds: 1));
              rewarded = true;
              onRewarded();
            } catch (e) {
              debugPrint('Rewarded ad failed: $e');
              rewarded = false;
            }
          }
          completer.complete(rewarded);
          _isAdShowing = false;
        },
        onCancelPressed: () {
          Navigator.of(ctx).pop();
          completer.complete(false);
          _isAdShowing = false;
        },
      ),
    );

    return completer.future;
  }

  static Future<void> maybeShowInterstitial() async {
    if (!AppConfig.isProduction) return;
    final isPro = await UsageManager.isPro();
    if (isPro) return;
    _exportCount++;
    if (_exportCount % 2 == 0) {
      try {
        debugPrint('Showing interstitial ad (simulated)');
      } catch (e) {
        debugPrint('Interstitial ad failed: $e');
      }
    }
  }

  static void resetExportCount() {
    _exportCount = 0;
  }
}

/// Premium rewarded ad dialog that matches QA Genie’s cyber‑dark theme.
class RewardedAdDialog extends StatelessWidget {
  final VoidCallback onWatchPressed;
  final VoidCallback onCancelPressed;

  const RewardedAdDialog({
    super.key,
    required this.onWatchPressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glossy icon badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: AppColors.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Unlock This Action",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Watch a short ad to continue.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Your support helps keep QA Genie accessible to everyone.",
                style: TextStyle(color: AppColors.textHint, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Primary button (full width)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onWatchPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: const Text(
                    "Watch Ad",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onCancelPressed,
                child: const Text(
                  "Not Now",
                  style: TextStyle(color: AppColors.textHint, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
