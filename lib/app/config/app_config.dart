// lib/app/config/app_config.dart

class AppConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  // Centralized Quotas
  static const int coreDailyGenerationLimit = 8;
  static const int proDailyGenerationLimit = 16;
  static const int rewardedDailyGenerationLimit = 6;

  static const int rewardedDailyExportLimit = 50;
  
  static bool testProMode = false;
  static const int maxConstraintsLength = 100;

  // Feature flags
  static bool get allowOfflineGeneration => !isProduction;
  static bool get allowDebugTools => !isProduction;
  static bool get allowMockAds => !isProduction;
  
  // Ad Units
  static String get rewardedTcGenerationAdUnit => 
      isProduction ? 'ca-app-pub-PRO_ID' : 'ca-app-pub-3940256099942544/5224354917';
}
