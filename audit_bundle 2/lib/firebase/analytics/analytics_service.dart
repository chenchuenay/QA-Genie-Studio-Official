import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalytics get instance => _analytics;

  static bool _enabled = true;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  static Future<void> logAppOpen() async {
    if (!_enabled) return;

    try {
      await _analytics.logAppOpen();
    } catch (e) {
      debugPrint('[AnalyticsService] logAppOpen failed: $e');
    }
  }

  static Future<void> logGenerationStarted({
    required String platform,
    required String mode,
    required int requestedCount,
  }) async {
    await _safeLog(
      eventName: 'generation_started',
      parameters: {
        'platform': platform,
        'mode': mode,
        'requested_count': requestedCount,
      },
    );
  }

  static Future<void> logGenerationCompleted({
    required String platform,
    required String mode,
    required int generatedCount,
    required int durationMs,
  }) async {
    await _safeLog(
      eventName: 'generation_completed',
      parameters: {
        'platform': platform,
        'mode': mode,
        'generated_count': generatedCount,
        'duration_ms': durationMs,
      },
    );
  }

  static Future<void> logGenerationFailed({
    required String platform,
    required String mode,
    required String reason,
  }) async {
    await _safeLog(
      eventName: 'generation_failed',
      parameters: {
        'platform': platform,
        'mode': mode,
        'reason': _truncate(reason),
      },
    );
  }

  static Future<void> logExport({
    required String format,
    required int caseCount,
  }) async {
    await _safeLog(
      eventName: 'export_completed',
      parameters: {'format': format, 'case_count': caseCount},
    );
  }

  static Future<void> logRewardedAd({required String placement}) async {
    await _safeLog(
      eventName: 'rewarded_ad_completed',
      parameters: {'placement': placement},
    );
  }

  static Future<void> logUpgradeIntent({required String source}) async {
    await _safeLog(eventName: 'upgrade_intent', parameters: {'source': source});
  }

  static Future<void> logBugReport({required String category}) async {
    await _safeLog(
      eventName: 'bug_report_submitted',
      parameters: {'category': category},
    );
  }

  static Future<void> logScreen({required String screenName}) async {
    if (!_enabled) return;

    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('[AnalyticsService] logScreen failed: $e');
    }
  }

  static Future<void> setUserId(String? userId) async {
    if (!_enabled) return;

    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('[AnalyticsService] setUserId failed: $e');
    }
  }

  static Future<void> _safeLog({
    required String eventName,
    Map<String, Object?> parameters = const {},
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters.map((key, value) => MapEntry(key, value ?? '')),
      );
    } catch (e) {
      debugPrint('[AnalyticsService] $eventName failed: $e');
    }
  }

  static String _truncate(String value, {int limit = 100}) {
    final sanitized = value.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (sanitized.length <= limit) {
      return sanitized;
    }

    return sanitized.substring(0, limit);
  }
}
