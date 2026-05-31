import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';

class AdService {
  static int _exportCount = 0;
  static bool _isAdShowing = false;

  static Future<bool> showRewardedAd({
    required String adUnitId,
    required VoidCallback onRewarded,
    required BuildContext context,
  }) async {
    if (_isAdShowing) return false;
    _isAdShowing = true;

    if (!AppConfig.isProduction) {
      final completer = Completer<bool>();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Unlock this feature',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Watch a short ad to continue.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                completer.complete(false);
              },
              child: const Text('No thanks', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onRewarded();
                completer.complete(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Watch Ad', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      final result = await completer.future;
      _isAdShowing = false;
      return result;
    } else {
      try {
        // Real AdMob rewarded ad – placeholder
        await Future.delayed(const Duration(seconds: 1));
        onRewarded();
        _isAdShowing = false;
        return true;
      } catch (e) {
        debugPrint('Rewarded ad failed: $e');
        _isAdShowing = false;
        return false;
      }
    }
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