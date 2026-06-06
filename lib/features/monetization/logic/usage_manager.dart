import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/core/config/app_environment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';

class UsageManager {
  static const _proKey = 'is_pro';

  static Future<SharedPreferences> _prefs() async =>
      SharedPreferences.getInstance();

  static Future<bool> isPro() async {
    if (!EnvironmentAuthority.isProduction && AppConfig.testProMode)
      return true;
    final prefs = await _prefs();
    return prefs.getBool(_proKey) ?? false;
  }

  static Future<void> setPro(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_proKey, value);
    // Also notify cloud function
    try {
      await FunctionsService.call(
        functionName: 'setUserPro',
        payload: {'isPro': value},
      );
    } catch (_) {}
  }

  /// Ask the cloud function if generation is allowed.
  static Future<bool> canGenerate({bool afterRewardedAd = false}) async {
    try {
      final result = await FunctionsService.call(
        functionName: 'checkGenerationQuota',
        payload: {'afterRewardedAd': afterRewardedAd},
      );
      return result['allowed'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Ask the cloud function if export is allowed.
  static Future<bool> canExport({bool rewarded = false}) async {
    try {
      final result = await FunctionsService.call(
        functionName: 'checkExportQuota',
        payload: {'rewarded': rewarded},
      );
      return result['allowed'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canExportSummary({bool rewarded = false}) async {
    return canExport(rewarded: rewarded);
  }

  /// Notify cloud function that a generation occurred (with optional ad token).
  static Future<void> incrementGeneration({bool rewarded = false}) async {
    try {
      await FunctionsService.call(
        functionName: 'trackGeneration',
        payload: {'rewarded': rewarded},
      );
    } catch (_) {}
  }

  static Future<void> incrementExport({bool rewarded = false}) async {
    try {
      await FunctionsService.call(
        functionName: 'trackExport',
        payload: {'rewarded': rewarded},
      );
    } catch (_) {}
  }

  static Future<void> incrementSummaryExport({bool rewarded = false}) async {
    return incrementExport(rewarded: rewarded);
  }

  static Future<void> resetLimits() async {
    try {
      await FunctionsService.call(functionName: 'resetDailyLimits');
    } catch (_) {}
  }

  // The following methods query the cloud function for UI hints.
  static Future<int> freeGensRemaining() async {
    try {
      final result = await FunctionsService.call(
        functionName: 'getQuotaStatus',
      );
      return result['freeGensRemaining'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> rewardedGensRemaining() async {
    try {
      final result = await FunctionsService.call(
        functionName: 'getQuotaStatus',
      );
      return result['rewardedGensRemaining'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> proGensRemaining() async {
    try {
      final result = await FunctionsService.call(
        functionName: 'getQuotaStatus',
      );
      return result['proGensRemaining'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> rewardedExportsRemaining() async {
    try {
      final result = await FunctionsService.call(
        functionName: 'getQuotaStatus',
      );
      return result['rewardedExportsRemaining'] ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
