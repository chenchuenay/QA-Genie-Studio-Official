import 'package:qa_app/features/monetization/logic/usage_manager.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  Future<void> showInterstitialIfAppropriate() async {
    final pro = await UsageManager.isPro();
    if (pro) return;
    final count = await UsageManager.getGenerationCount();
    if (count > 0 && count % 2 == 0) {
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
