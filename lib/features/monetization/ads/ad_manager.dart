import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qa_genie/core/config/app_environment.dart';
import 'package:qa_genie/shared/dialogs/ad_loading_dialog.dart';
import 'package:qa_genie/features/monetization/ads/ad_units.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';

/// AD ORCHESTRATOR: Unified singleton for all ad-related revenue.
/// Optimized for: Pre-loading (Investor), Safety (Reviewer), and Performance (Designer).
class AdManager {
  static final AdManager _instance = AdManager._();
  factory AdManager() => _instance;
  AdManager._();

  RewardedAd? _rewardedAd;
  String? _loadedAdUnitId;
  int _exportCount = 0;
  int _adLoadRetries = 0;
  static const int _maxAdLoadRetries = 2;
  static const Duration _adRetryDelay = Duration(seconds: 3);
  Completer<void>? _emergencyLoadCompleter;

  /// UI Authority: Single notifier for the whole app to prevent flickering
  final ValueNotifier<bool> isAdLoading = ValueNotifier(false);

  bool get isAdReady => _rewardedAd != null;

  /// INVESTOR: Smart pre-loading ensures we are "one step ahead" of the user.
  /// If [adUnitId] is null, it defaults to the Generation unit (highest volume).
  Future<void> loadRewardedAd({String? adUnitId}) async {
    final targetUnit = adUnitId ?? AdUnits.rewardedTcGeneration;

    // If already loaded or currently loading, ignore
    if (_rewardedAd != null && _loadedAdUnitId == targetUnit) return;
    if (isAdLoading.value) return;

    // DEVELOPER: Dispose old ad if we are switching units to save memory
    if (_rewardedAd != null && _loadedAdUnitId != targetUnit) {
      debugPrint('♻️ AdManager: Switching units. Disposing stale ad.');
      await _rewardedAd!.dispose();
      _rewardedAd = null;
      _loadedAdUnitId = null;
    }

    isAdLoading.value = true;
    debugPrint('📢 AdManager: [REVENUE] Pre-loading Unit: $targetUnit');

    // SAFETY WATCHDOG: Force-reset isAdLoading after 10s if SDK callback never fires
    final watchdog = Timer(const Duration(seconds: 10), () {
      if (isAdLoading.value) {
        debugPrint('⏰ AdManager: [WATCHDOG] Load timeout. Force-resetting isAdLoading.');
        isAdLoading.value = false;
      }
    });

    try {
      await RewardedAd.load(
        adUnitId: targetUnit,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            watchdog.cancel();
            debugPrint('✅ AdManager: [REVENUE] Ad Ready: $targetUnit');
            _rewardedAd = ad;
            _loadedAdUnitId = targetUnit;
            isAdLoading.value = false;
            _emergencyLoadCompleter?.complete();
          },
          onAdFailedToLoad: (error) {
            watchdog.cancel();
            debugPrint('❌ AdManager: [LOSS] Load Failed ($targetUnit)');
            debugPrint('   Error code: ${error.code}');
            debugPrint('   Message: ${error.message}');
            debugPrint('   ResponseInfo: ${error.responseInfo}');
            _rewardedAd = null;
            _loadedAdUnitId = null;

            if (_adLoadRetries < _maxAdLoadRetries) {
              _adLoadRetries++;
              debugPrint('🔄 AdManager: Retrying ad load (#$_adLoadRetries) in ${_adRetryDelay.inSeconds}s');
              Future.delayed(_adRetryDelay, () {
                isAdLoading.value = false;
                loadRewardedAd(adUnitId: targetUnit);
              });
            } else {
              _adLoadRetries = 0;
              isAdLoading.value = false;
              _emergencyLoadCompleter?.complete();
              debugPrint('❌ AdManager: [LOSS] All retries exhausted. Revenue opportunity lost.');
            }
          },
        ),
      );
    } catch (e) {
      watchdog.cancel();
      _rewardedAd = null;
      _loadedAdUnitId = null;
      if (_adLoadRetries < _maxAdLoadRetries) {
        _adLoadRetries++;
        debugPrint('🔄 AdManager: Retrying ad load (#$_adLoadRetries) after exception');
        Future.delayed(_adRetryDelay, () {
          isAdLoading.value = false;
          loadRewardedAd(adUnitId: targetUnit);
        });
      } else {
        _adLoadRetries = 0;
        isAdLoading.value = false;
        _emergencyLoadCompleter?.complete();
        debugPrint('❌ AdManager: [ERROR] All retries exhausted: $e');
      }
    }
  }

  /// PROJECT OWNER: Logical transition interstitials (Every 2nd export).
  Future<void> maybeShowInterstitial() async {
    if (!AppConfig.isProduction) return;
    final isPro = await UsageManager.isPro();
    if (isPro) return;

    _exportCount++;
    if (_exportCount % 2 == 0) {
      debugPrint(
        '📢 AdManager: [REVENUE] Interstitial threshold met (Deferred to post-task flow)',
      );
      // Future: InterstitialAd.load(...)
    }
  }

  void resetExportCount() => _exportCount = 0;

  /// ONE-STOP-SHOP: Shows the recovery dialog if ads are delayed.
  void showStatusDialog(BuildContext context, {required VoidCallback onRetry}) {
    showBlurredDialog(
      context,
      builder: (ctx) => AdLoadingDialog(onRetry: onRetry),
    );
  }

  /// REVENUE ENGINE: Shows the pre-loaded ad or performs an emergency load.
  /// Includes a 45s Safety Watchdog for Play Store compliance.
  Future<String?> showRewardedAd({String? adUnitId}) async {
    final targetUnit = adUnitId ?? AdUnits.rewardedTcGeneration;

    if (EnvironmentAuthority.allowMockAds) {
      debugPrint('🧪 MOCK AD: bypassing real ad for dev mode');
      return 'mock_ad_token_${DateTime.now().millisecondsSinceEpoch}';
    }

    // EMERGENCY LOAD: If the user is faster than our pre-loader
    if (!isAdReady || _loadedAdUnitId != targetUnit) {
      debugPrint(
        '⚠️ AdManager: [RECOVERY] Correct unit not ready. Forcing load...',
      );
      _emergencyLoadCompleter = Completer<void>();
      await loadRewardedAd(adUnitId: targetUnit);
      await _emergencyLoadCompleter!.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => null,
      );
      _emergencyLoadCompleter = null;
    }

    if (!isAdReady) {
      debugPrint(
        '❌ AdManager: [LOSS] Final recovery failed. Revenue opportunity lost.',
      );
      return null;
    }

    final completer = Completer<String?>();
    String? transactionId;
    bool earned = false;

    // REVIEWER: 90s Watchdog ensures the app never hangs (Compliance)
    final watchdog = Timer(const Duration(seconds: 90), () {
      if (!completer.isCompleted) {
        debugPrint('⏰ AdManager: [WATCHDOG] Safety reset triggered.');
        _rewardedAd?.dispose();
        _rewardedAd = null;
        isAdLoading.value = false;
        completer.complete(null);
      }
    });

    final lastUnit = _loadedAdUnitId;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('🏠 AdManager: [UX] Ad Closed. Earned: $earned');
        ad.dispose();
        _rewardedAd = null;
        _loadedAdUnitId = null;
        watchdog.cancel();

        if (!completer.isCompleted) {
          completer.complete(earned ? transactionId : null);
        }

        // Pre-load next ad with the same unit after a short cool-down
        Future.delayed(const Duration(seconds: 2), () {
          loadRewardedAd(adUnitId: lastUnit);
        });
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ AdManager: [LOSS] Show Error: $error');
        ad.dispose();
        _rewardedAd = null;
        _loadedAdUnitId = null;
        watchdog.cancel();
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    try {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
          transactionId =
              '${reward.type}_${DateTime.now().millisecondsSinceEpoch}_${reward.amount}';
          debugPrint('🎁 Reward earned. Transaction ID: $transactionId');
        },
      );
    } catch (e) {
      debugPrint('❌ AdManager: Show failed with error $e');
      watchdog.cancel();
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _loadedAdUnitId = null;
      if (!completer.isCompleted) completer.complete(null);
    }

    return completer.future;
  }
}
