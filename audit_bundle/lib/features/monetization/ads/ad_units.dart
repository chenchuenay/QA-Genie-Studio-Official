class AdUnits {
  // Google's official test ad unit IDs (work without approval)
  static const String _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // Your real AdMob IDs (replace after publication)
  static const String _realRewardedGeneration =
      'ca-app-pub-5950082050771694/8569180768';
  static const String _realRewardedExport =
      'ca-app-pub-5950082050771694/2889478678';
  static const String _realRewardedSummary =
      'ca-app-pub-5950082050771694/6327533956';

  // Force test IDs globally until app is live
  static String get rewardedTcGeneration => _testRewarded;
  static String get rewardedTcExport => _testRewarded;
  static String get rewardedSummaryExport => _testRewarded;

  // Native Ads
  static const String _testNative = 'ca-app-pub-3940256099942544/2247696110';
  static const String _realNativeSuites = 'ca-app-pub-5950082050771694/9143895834';

  static String get nativeSuites {
    // Return test ID for now as requested
    return _testNative;
  }
}
