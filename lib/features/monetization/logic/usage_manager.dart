import 'package:flutter/foundation.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';

class UsageManager {
  static const _proKey = 'is_pro';
  static Map<String, dynamic>? _dashboardCache;
  static DateTime? _dashboardCacheTime;
  static String? _dashboardCacheUid;
  static const Duration _cacheDuration = Duration(seconds: 60);

  static Future<SharedPreferences> _prefs() async => SharedPreferences.getInstance();

  static Future<bool> isPro() async {
    // Dev override via test mode screen
    if (AppConfig.testProMode) return true;

    // Read from Firestore (server-authoritative) via dashboard
    final dashboard = await _getDashboard();
    if (dashboard['isPro'] == true) return true;

    // Fallback: SharedPreferences (dev mode only; production is server-authoritative)
    if (!AppConfig.isProduction) {
      final prefs = await _prefs();
      return prefs.getBool(_proKey) ?? false;
    }
    return false;
  }

  static Future<void> setPro(bool value) async {
    if (!AppConfig.allowDebugTools) {
      if (value) {
        debugPrint('⚠️ UsageManager.setPro: blocked in production; grant via Firestore console');
      }
      return;
    }
    final prefs = await _prefs();
    await prefs.setBool(_proKey, value);
    try {
      await FunctionsService.call(functionName: 'setMemberPro', payload: {'isPro': value});
    } catch (e) {
      debugPrint('UsageManager.setPro error: $e');
    }
  }

  static int _clampRemaining(num limit, num used) =>
      (limit - used).toInt().clamp(0, limit.toInt());

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
      final result = await FunctionsService.call(functionName: 'checkExportQuota', payload: {'rewarded': rewarded});
      return result['allowed'] == true;
    } catch (e) {
      debugPrint('UsageManager.canGenerate error: $e');
      return false;
    }
  }

  static Future<bool> canExportSummary({bool rewarded = false}) async => canExport(rewarded: rewarded);

  static Future<void> incrementGeneration({int count = 8, bool rewarded = false}) async {
    _invalidateCache();
  }

  static Future<void> incrementExport({bool summary = false, String target = 'unknown', String extension = ''}) async {
    try {
      await FunctionsService.call(functionName: 'trackExport', payload: {'summary': summary, 'target': target, 'extension': extension});
      _invalidateCache();
    } catch (e) {
      debugPrint('UsageManager.incrementExport error: $e');
    }
  }

  static Future<void> incrementSummaryExport({String target = 'pdf', String extension = 'pdf'}) async =>
      incrementExport(summary: true, target: target, extension: extension);

  static Future<void> trackProInterest(String source) async {
    try {
      await FunctionsService.trackProInterest(source);
    } catch (e) {
      debugPrint('UsageManager.trackProInterest error: $e');
    }
  }

  static Future<void> resetLimits() async {
    if (!AppConfig.allowDebugTools) return;
    try {
      await FunctionsService.call(functionName: 'resetDailyLimits');
    } catch (e) {
      debugPrint('UsageManager.resetLimits error: $e');
    }
  }

  static Future<Map<String, dynamic>>? _dashboardFetch;
  static int _dashboardEpoch = 0;

  static void invalidateCache() {
    _dashboardCache = null;
    _dashboardCacheTime = null;
    _dashboardCacheUid = null;
    _dashboardFetch = null;
    _dashboardEpoch++;
  }

  static void _invalidateCache() => invalidateCache();

  static String _currentUid() => AuthService.currentMember?.uid ?? 'guest';

  static Future<Map<String, dynamic>> _getDashboard() async {
    final now = DateTime.now();
    final uid = _currentUid();
    if (_dashboardCache != null && _dashboardCacheUid == uid && _dashboardCacheTime != null && now.difference(_dashboardCacheTime!) < _cacheDuration) {
      return _dashboardCache!;
    }
    // Deduplicate concurrent fetches
    if (_dashboardFetch != null) {
      await _dashboardFetch;
      if (_dashboardCacheUid == uid) return _dashboardCache ?? {};
    }
    _dashboardFetch = _fetchDashboard(now, uid);
    try {
      return await _dashboardFetch!;
    } finally {
      _dashboardFetch = null;
    }
  }

  static Future<Map<String, dynamic>> _fetchDashboard(DateTime now, String uid) async {
    final epoch = _dashboardEpoch;
    try {
      final result = await FunctionsService.call(functionName: 'getMemberDashboard', payload: {'type': 'member'});
      if (epoch == _dashboardEpoch) {
        _dashboardCache = result;
        _dashboardCacheTime = now;
        _dashboardCacheUid = uid;
      } else {
        debugPrint('UsageManager._fetchDashboard: discarding stale result (epoch changed)');
      }
      return result;
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
      return _dashboardCache ?? {};
    }
  }

  static Future<int> freeGensRemaining() async {
    final isProFlag = await isPro();
    if (isProFlag) {
      final dashboard = await _getDashboard();
      final metrics = dashboard['metrics'] ?? {};
      final used = metrics['proFreeGenCount'] ?? 0;
      return _clampRemaining(AppConfig.proFreeBatchesPerDay, used);
    } else {
      // Core has zero free generations
      return 0;
    }
  }

  static Future<int> rewardedGensRemaining() async {
    final dashboard = await _getDashboard();
    final remaining = dashboard['rewardedGensRemaining'];
    if (remaining is int) return remaining;
    final metrics = dashboard['metrics'] ?? {};
    final used = metrics['rewardedGenCount'] ?? 0;
    final guestTier = dashboard['guestTier'] as String?;
    if (guestTier == 'returning') {
      return _clampRemaining(AppConfig.returningGuestBatchesPerDay, used);
    }
    return _clampRemaining(AppConfig.coreRewardedBatchesPerDay, used);
  }

  static Future<int> proGensRemaining() async {
    final dashboard = await _getDashboard();
    final remaining = dashboard['proGensRemaining'];
    if (remaining is int) return remaining;
    final metrics = dashboard['metrics'] ?? {};
    final used = metrics['proFreeGenCount'] ?? 0;
    return _clampRemaining(AppConfig.proFreeBatchesPerDay, used);
  }

  static Future<Map<String, dynamic>> getDashboardData() => _getDashboard();

  /// Returns true if the current member can submit feedback/reports.
  /// Only signed-in (non-guest) members can give feedback. Guests must sign in.
  static bool get canGiveFeedback => !AuthService.isGuest;

  /// Returns true if the star rating should be shown in export success dialog.
  /// Shown for signed-in members and first-time (6-quota) guests.
  /// Hidden for returning (1-quota) guests.
  static Future<bool> canShowStars() async {
    if (AuthService.isGuest) {
      if (_dashboardCache?['guestTier'] == null) {
        await _getDashboard();
      }
      return _dashboardCache?['guestTier'] == 'first';
    }
    return true;
  }

  static Future<Map<String, int>> getLifetimeStats() async {
    final dashboard = await _getDashboard();
    final metrics = dashboard['metrics'] ?? {};
    final exports = dashboard['exports'] ?? {};
    return {
      'generations': ((metrics['lifetimeGeneratedCases'] ?? 0) as num).toInt(),
      'exports': ((exports['lifetimeExports'] ?? 0) as num).toInt(),
    };
  }

  static Future<DateTime?> getResetTime() async {
    final dashboard = await _getDashboard();
    final timestamp = dashboard['resetTimestamp'] as String?;
    if (timestamp != null) {
      try {
        return DateTime.parse(timestamp);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<int> rewardedExportsRemaining() async {
    try {
      final result = await FunctionsService.call(functionName: 'checkExportQuota', payload: {'rewarded': true});
      return result['remaining'] ?? 0;
    } catch (e) {
      debugPrint('UsageManager.rewardedExportsRemaining error: $e');
      return 0;
    }
  }
}
