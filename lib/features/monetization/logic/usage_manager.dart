import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/core/config/app_environment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/core/security/security_bridge.dart';
import 'package:qa_genie/core/network/cloud_authority_service.dart';
// lib/features/monetization/logic/usage_manager.dart

class UsageManager {
  static const _generationCountKey = 'generation_count';

  static const _rewardedGenerationCountKey = 'rewarded_generation_count';

  static const _exportCountKey = 'export_count';

  static const _summaryExportCountKey = 'summary_export_count';

  static const _rewardedExportCountKey = 'rewarded_export_count';

  static const _proKey = 'is_pro';

  static const int _freeDailyGenerationLimit = 1;

  static const int _rewardedDailyGenerationLimit = 5;

  static const int _proDailyGenerationLimit = 15;

  static const int _rewardedDailyExportLimit = 50;

  static Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  static Future<bool> isPro() async {
    if (!EnvironmentAuthority.isProduction && AppConfig.testProMode) {
      return true;
    }

    final prefs = await _prefs();

    return prefs.getBool(_proKey) ?? false;
  }

  static Future<void> setPro(bool value) async {
    final prefs = await _prefs();

    await prefs.setBool(_proKey, value);
  }

  static Future<int> getGenerationCount() async {
    final prefs = await _prefs();

    return prefs.getInt(_generationCountKey) ?? 0;
  }

  static Future<int> getRewardedGenerationCount() async {
    final prefs = await _prefs();

    return prefs.getInt(_rewardedGenerationCountKey) ?? 0;
  }

  static Future<bool> canGenerate({bool afterRewardedAd = false}) async {
    if (SecurityBridge.instance.canBypassLimits) {
      return true;
    }

    final pro = await isPro();

    if (pro) {
      return _checkServerQuota(
        type: 'generation',
        limit: _proDailyGenerationLimit,
      );
    }

    final freeCount = await getGenerationCount();

    final rewardedCount = await getRewardedGenerationCount();

    if (freeCount < _freeDailyGenerationLimit) {
      return true;
    }

    if (!afterRewardedAd) {
      return false;
    }

    return rewardedCount < _rewardedDailyGenerationLimit;
  }

  static Future<void> incrementGeneration({bool rewarded = false}) async {
    final prefs = await _prefs();

    if (rewarded) {
      final rewardedCount = await getRewardedGenerationCount();

      await prefs.setInt(_rewardedGenerationCountKey, rewardedCount + 1);
    } else {
      final count = await getGenerationCount();

      await prefs.setInt(_generationCountKey, count + 1);
    }

    await CloudAuthorityService.instance.trackUsage(
      type: 'generation',
      value: 1,
    );
  }

  static Future<int> freeGensRemaining() async {
    final count = await getGenerationCount();

    final remaining = _freeDailyGenerationLimit - count;

    return remaining < 0 ? 0 : remaining;
  }

  static Future<int> rewardedGensRemaining() async {
    final count = await getRewardedGenerationCount();

    final remaining = _rewardedDailyGenerationLimit - count;

    return remaining < 0 ? 0 : remaining;
  }

  static Future<int> proGensRemaining() async {
    final count = await getGenerationCount();

    final remaining = _proDailyGenerationLimit - count;

    return remaining < 0 ? 0 : remaining;
  }

  static Future<int> getExportCount() async {
    final prefs = await _prefs();

    return prefs.getInt(_exportCountKey) ?? 0;
  }

  static Future<int> getSummaryExportCount() async {
    final prefs = await _prefs();

    return prefs.getInt(_summaryExportCountKey) ?? 0;
  }

  static Future<int> getRewardedExportCount() async {
    final prefs = await _prefs();

    return prefs.getInt(_rewardedExportCountKey) ?? 0;
  }

  static Future<bool> canExport({bool rewarded = false}) async {
    final pro = await isPro();

    if (pro) return true;

    final exportCount = await getExportCount();

    if (exportCount < 1) {
      return true;
    }

    if (!rewarded) {
      return false;
    }

    final rewardedExports = await getRewardedExportCount();

    return rewardedExports < _rewardedDailyExportLimit;
  }

  static Future<bool> canExportSummary({bool rewarded = false}) async {
    final pro = await isPro();

    if (pro) return true;

    final summaryCount = await getSummaryExportCount();

    if (summaryCount < 1) {
      return true;
    }

    if (!rewarded) {
      return false;
    }

    final rewardedExports = await getRewardedExportCount();

    return rewardedExports < _rewardedDailyExportLimit;
  }

  static Future<void> incrementExport({bool rewarded = false}) async {
    final prefs = await _prefs();

    final count = await getExportCount();

    await prefs.setInt(_exportCountKey, count + 1);

    if (rewarded) {
      final rewardedCount = await getRewardedExportCount();

      await prefs.setInt(_rewardedExportCountKey, rewardedCount + 1);
    }

    await CloudAuthorityService.instance.trackUsage(type: 'export', value: 1);
  }

  static Future<void> incrementSummaryExport({bool rewarded = false}) async {
    final prefs = await _prefs();

    final count = await getSummaryExportCount();

    await prefs.setInt(_summaryExportCountKey, count + 1);

    if (rewarded) {
      final rewardedCount = await getRewardedExportCount();

      await prefs.setInt(_rewardedExportCountKey, rewardedCount + 1);
    }

    await CloudAuthorityService.instance.trackUsage(
      type: 'summary_export',
      value: 1,
    );
  }

  static Future<int> rewardedExportsRemaining() async {
    final count = await getRewardedExportCount();

    final remaining = _rewardedDailyExportLimit - count;

    return remaining < 0 ? 0 : remaining;
  }

  static Future<void> resetDailyUsage() async {
    final prefs = await _prefs();

    await prefs.remove(_generationCountKey);

    await prefs.remove(_rewardedGenerationCountKey);

    await prefs.remove(_rewardedExportCountKey);
  }

  static Future<void> resetLimits() {
    return resetDailyUsage();
  }

  static Future<bool> _checkServerQuota({
    required String type,
    required int limit,
  }) async {
    try {
      return await CloudAuthorityService.instance.validateQuota(
        type: type,
        limit: limit,
      );
    } catch (_) {
      return false;
    }
  }
}
