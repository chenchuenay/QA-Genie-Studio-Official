import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/monetization/ads/ad_manager.dart';

void main() {
  group('AdManager', () {
    late AdManager adManager;

    setUp(() {
      adManager = AdManager();
    });

    test('is singleton', () {
      expect(AdManager(), same(adManager));
    });

    test('isAdReady returns false initially', () {
      expect(adManager.isAdReady, false);
    });

    test('isAdLoading is false initially', () {
      expect(adManager.isAdLoading.value, false);
    });

    test('resetExportCount does not throw', () {
      expect(() => adManager.resetExportCount(), returnsNormally);
    });

    test('showRewardedAd returns mock token in dev mode', () async {
      final token = await adManager.showRewardedAd();
      expect(token, startsWith('mock_ad_token_'));
    });
  });
}
