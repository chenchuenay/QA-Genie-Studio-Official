import 'package:flutter/foundation.dart';
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
    if (!AppConfig.allowDebugTools) return;
    final prefs = await _prefs();
    await prefs.setBool(_proKey, value);
    try {
      await FunctionsService.call(
        functionName: 'setUserPro',
        payload: {'isPro': value},
      );
    } catch (_) {}
  }

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

  static Future<void> incrementGeneration({int count = 8, bool rewarded = false}) async {
    try {
      await FunctionsService.call(
        functionName: 'trackGeneration',
        payload: {'generatedCount': count},
      );
    } catch (_) {}
  }

  static Future<void> incrementExport({
    bool summary = false,
    String target = 'unknown',
    String extension = '',
  }) async {
    try {
      await FunctionsService.call(
        functionName: 'trackExport',
        payload: {
          'summary': summary,
          'target': target,
          'extension': extension,
        },
      );
    } catch (_) {}
  }

  static Future<void> incrementSummaryExport({
    String target = 'pdf',
    String extension = 'pdf',
  }) async {
    return incrementExport(
      summary: true,
      target: target,
      extension: extension,
    );
  }

  static Future<void> resetLimits() async {
    if (!AppConfig.allowDebugTools) return;
    try {
      await FunctionsService.call(functionName: 'resetDailyLimits');
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> _getDashboard() async {
    try {
      final result = await FunctionsService.call(
        functionName: 'getUserDashboard',
        payload: {'type': 'user'},
      );
      return result;
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
      return {};
    }
  }

  static Future<int> freeGensRemaining() async {
    final dashboard = await _getDashboard();
    final metrics = dashboard['metrics'] ?? {};
    return (AppConfig.coreDailyBatchesLimit - (metrics['coreGenCount'] ?? 0)).toInt();
  }

  static Future<int> rewardedGensRemaining() async {
    final dashboard = await _getDashboard();
    final metrics = dashboard['metrics'] ?? {};
    final used = metrics['rewardedGenCount'] ?? 0;
    return (AppConfig.coreDailyBatchesLimit - used).toInt();
  }

  static Future<int> proGensRemaining() async {
    final dashboard = await _getDashboard();
    final metrics = dashboard['metrics'] ?? {};
    final used = metrics['proGenCount'] ?? 0;
    return (AppConfig.proDailyBatchesLimit - used).toInt();
  }

  static Future<DateTime?> getResetTime() async {
    final dashboard = await _getDashboard();
    final timestamp = dashboard['resetTimestamp'] as String?;
    if (timestamp != null) return DateTime.parse(timestamp);
    return null;
  }

  static Future<int> rewardedExportsRemaining() async {
    try {
      final result = await FunctionsService.call(
        functionName: 'checkExportQuota',
        payload: {'rewarded': true},
      );
      return result['remaining'] ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
