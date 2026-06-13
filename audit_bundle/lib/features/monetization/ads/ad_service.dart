import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/core/config/app_environment.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qa_genie/features/monetization/ads/ad_units.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';

class AdService {
  static int _exportCount = 0;
  static RewardedAd? _rewardedAd;
  static final ValueNotifier<bool> isAdLoading = ValueNotifier(false);

  static Future<String?> showRewardedAd({
    required String adUnitId,
    required BuildContext context,
  }) async {
    isAdLoading.value = true;
    final completer = Completer<String?>();
    String? rewardToken;

    try {
      if (EnvironmentAuthority.allowMockAds) {
        debugPrint('🎭 AdService: Mock ad triggered (MODE=dev)');
        await Future.delayed(const Duration(milliseconds: 500));
        isAdLoading.value = false;
        return 'mock_${DateTime.now().millisecondsSinceEpoch}';
      }

      debugPrint('📢 AdService: Attempting to load ad...');
      debugPrint('📍 AdService: Unit ID: $adUnitId');

      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('✅ AdService: Ad loaded successfully');
            _rewardedAd = ad;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('🏠 AdService: Ad dismissed. Returning token: $rewardToken');
                ad.dispose();
                _rewardedAd = null;
                isAdLoading.value = false;
                if (!completer.isCompleted) completer.complete(rewardToken);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('❌ AdService: Failed to show ad: $error');
                ad.dispose();
                _rewardedAd = null;
                isAdLoading.value = false;
                if (!completer.isCompleted) completer.complete(null);
              },
            );

            ad.show(
              onUserEarnedReward: (ad, reward) {
                debugPrint('🏆 AdService: Reward earned');
                rewardToken = FunctionsService.generateAdToken();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ AdService: Ad failed to load: $error');
            isAdLoading.value = false;
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );

      Future.delayed(const Duration(seconds: 45), () {
        if (!completer.isCompleted) {
          debugPrint('⏰ AdService: Ad loading/completion timeout');
          _rewardedAd?.dispose();
          _rewardedAd = null;
          isAdLoading.value = false;
          completer.complete(null);
        }
      });

      return completer.future;
    } catch (e) {
      isAdLoading.value = false;
      return null;
    }
  }

  static Future<void> maybeShowInterstitial() async {
    if (!AppConfig.isProduction) return;
    final isPro = await UsageManager.isPro();
    if (isPro) return;
    _exportCount++;
    if (_exportCount % 2 == 0) {
      debugPrint('Interstitial ad ready (not implemented yet)');
    }
  }

  static void resetExportCount() {
    _exportCount = 0;
  }
}
