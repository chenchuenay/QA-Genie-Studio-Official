// lib/app/config/app_config.dart

class AppConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  static bool testProMode = false;

  static const int maxConstraintsLength = 100;

  static const int freeDailyGenerationLimit = 0;
  static const int rewardedDailyGenerationLimit = 6;
  static const int proDailyGenerationLimit = 15;

  static const int rewardedDailyExportLimit = 50;
  static const int freeLifetimeExports = 0;
  static const int freeLifetimeSummaryExports = 0;

  // NEW: Feature flags based on build flavor
  static bool get allowOfflineGeneration => !isProduction;
  static bool get allowDebugTools => !isProduction;
  static bool get allowMockAds => !isProduction;
}
