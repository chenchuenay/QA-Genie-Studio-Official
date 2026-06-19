import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/monetization/ads/ad_units.dart';

void main() {
  group('AdUnits', () {
    test('rewardedTcGeneration returns test rewarded ad unit id', () {
      expect(AdUnits.rewardedTcGeneration, 'ca-app-pub-3940256099942544/5224354917');
    });

    test('rewardedTcExport returns test rewarded ad unit id', () {
      expect(AdUnits.rewardedTcExport, 'ca-app-pub-3940256099942544/5224354917');
    });

    test('rewardedSummaryExport returns test rewarded ad unit id', () {
      expect(AdUnits.rewardedSummaryExport, 'ca-app-pub-3940256099942544/5224354917');
    });

    test('interstitialGeneral returns test interstitial ad unit id', () {
      expect(AdUnits.interstitialGeneral, 'ca-app-pub-3940256099942544/1033173712');
    });

    test('nativeSuites returns test native ad unit id', () {
      expect(AdUnits.nativeSuites, 'ca-app-pub-3940256099942544/2247696110');
    });
  });
}
