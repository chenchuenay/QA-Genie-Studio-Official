// lib/app/config/app_config.dart

class AppConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  // ============================================================
  // QUOTA & LIMITS – CHANGE THESE VALUES ONLY HERE
  // ============================================================

  // Generation batches per day
  static const int coreFreeBatchesPerDay = 0;           // Core: 0 free generations
  static const int coreRewardedBatchesPerDay = 6;       // Core: 6 rewarded ad generations
  static const int proFreeBatchesPerDay = 15;           // Pro: 15 free generations

  // Cases per batch
  static const int coreCasesPerBatch = 10;
  static const int proCasesPerBatch = 20;

  // Export limits
  static const int coreDailyExportLimit = 50;           // Core: 50 exports per day
  // Pro has unlimited exports (no limit)

  // ============================================================
  // FEATURE FLAGS & MISC
  // ============================================================
  static bool testProMode = false;
  static const int maxConstraintsLength = 100;

  static bool get allowOfflineGeneration => !isProduction;
  static bool get allowDebugTools => !isProduction;
  static bool get allowMockAds => !isProduction;

  // Ad unit IDs (test IDs for pre‑launch)
  static String get rewardedTcGenerationAdUnit => 'ca-app-pub-3940256099942544/5224354917';
}
