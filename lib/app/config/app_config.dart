// lib/app/config/app_config.dart

class AppConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  static bool testProMode = false;

  static const int maxConstraintsLength = 100;

  static const int freeDailyGenerationLimit = 1;

  static const int rewardedDailyGenerationLimit = 5;

  static const int proDailyGenerationLimit = 15;

  static const int rewardedDailyExportLimit = 50;

  static const int freeLifetimeExports = 1;

  static const int freeLifetimeSummaryExports = 1;
}
