class AdUnits {
  // --- TEST AD UNIT IDS (Use these while testing) ---
  static const String _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testNative = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';

  // --- REAL AD UNIT IDS (Use these after app launch) ---
  // static const String realRewardedGeneration = 'ca-app-pub-5950082050771694/8569180768';
  // static const String realRewardedExport = 'ca-app-pub-5950082050771694/2889478678';
  // static const String realRewardedSummary = 'ca-app-pub-5950082050771694/6327533956';
  // static const String realInterstitial = 'ca-app-pub-5950082050771694/4276085687';
  // static const String realNativeSuites = 'ca-app-pub-5950082050771694/9143895834';

  // --- PUBLIC GETTERS (Forced to Test IDs for pre-launch release testing) ---
  static String get rewardedTcGeneration => _testRewarded;
  static String get rewardedTcExport => _testRewarded;
  static String get rewardedSummaryExport => _testRewarded;
  static String get interstitialGeneral => _testInterstitial;
  static String get nativeSuites => _testNative;
}
