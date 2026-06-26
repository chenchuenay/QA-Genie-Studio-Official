// lib/app/config/app_config.dart
//
// ==================================================================
// ☝️ SINGLE SOURCE OF TRUTH for all tunable app values
// ==================================================================
//
// Environment detection (dev vs prod) lives in EnvironmentAuthority
// (lib/core/config/app_environment.dart).  This file holds ONLY the
// numeric/string constants you may want to tweak day-to-day.
//
// HOW TO RUN:
//   flutter run  --dart-define=IS_DEV=true   → dev Firebase + dev features
//   flutter run                               → prod Firebase + prod features
// ==================================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/core/config/app_environment.dart';

class AppConfig {
  /// 🏭 Whether this is a production build.
  /// Controlled by `--dart-define=MODE=prod`.
  static bool get isProduction => EnvironmentAuthority.isProd;

  // ============================================================
  // QUOTA & LIMITS – CHANGE THESE VALUES ONLY HERE
  // ============================================================

  // Generation batches per day
  static const int coreFreeBatchesPerDay = 0;           // Core: 0 free generations
  static const int coreRewardedBatchesPerDay = 6;       // Core: 6 rewarded ad generations
  static const int returningGuestBatchesPerDay = 1;     // Returning guest: 1 quota
  static const int proFreeBatchesPerDay = 15;           // Pro: 15 free generations

  // Cases per batch
  static const int coreCasesPerBatch = 10;
  static const int proCasesPerBatch = 20;

  // Export limits
  static const int coreDailyExportLimit = 50;           // Core: 50 exports per day
  // Pro has unlimited exports (no limit)

  // ============================================================
  // PRICING
  // ============================================================
  static const String proMonthlyPrice = '\$6.99';

  // ============================================================
  // FEATURE FLAGS & MISC
  // ============================================================
  static const int maxConstraintsLength = 100;

  static bool get allowMockAds => EnvironmentAuthority.allowMockAds;

  // ============================================================
  // AD UNIT IDS (test IDs for pre‑launch)
  // ============================================================
  static String get rewardedTcGenerationAdUnit => 'ca-app-pub-3940256099942544/5224354917';

  // Cached SharedPreferences singleton — avoids redundant platform channel calls
  static SharedPreferences? _cachedPrefs;
  static Future<SharedPreferences> get sharedPrefs async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }
}
