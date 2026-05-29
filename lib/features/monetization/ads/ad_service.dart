import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
// lib/features/monetization/ads/ad_service.dart


class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() => _instance;

  AdService._internal();

  Future<void> showInterstitialIfAppropriate() async {
    final pro = await UsageManager.isPro();

    if (pro) return;

    final generationCount = await UsageManager.getGenerationCount();

    final rewardedCount = await UsageManager.getRewardedGenerationCount();

    final total = generationCount + rewardedCount;

    if (total > 0 && total % 2 == 0) {
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  Future<bool> showRewardedAd() async {
    final pro = await UsageManager.isPro();

    if (pro) return true;

    await Future.delayed(const Duration(milliseconds: 800));

    return true;
  }
}
