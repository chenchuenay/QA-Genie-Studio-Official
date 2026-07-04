import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/core/config/app_environment.dart';

class CloudSyncService {
  static const _lastSyncKey = 'cloud_last_sync_ms';
  static const _syncIntervalHours = 24;
  static bool _isPushing = false;
  static DateTime? _lastPullTime;

  static bool get canSync => AuthService.currentMember != null && !AuthService.isGuest;
  static bool get _canSync => canSync;

  static Future<int> getLastSyncMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSyncKey) ?? 0;
  }

  static Future<void> _setLastSyncNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<String> getLastSyncedText() async {
    final ms = await getLastSyncMs();
    if (ms == 0) return 'Never';
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inMinutes < 1) return 'Sync just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  static Future<bool> shouldAutoSync() async {
    final ms = await getLastSyncMs();
    if (ms == 0) return AuthService.currentMember != null && !AuthService.isGuest;
    final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    return elapsed.inHours >= _syncIntervalHours;
  }

  static DateTime? get lastPullTime => _lastPullTime;

  static Future<int> pushPendingSuites() async {
    debugPrint('🔁 SYNC: pushPendingSuites called, member=${AuthService.currentMember?.uid}, isGuest=${AuthService.isGuest}');
    if (!_canSync) {
      debugPrint('🔁 SYNC: GUARD FAIL - _canSync false (member=${AuthService.currentMember?.uid}, isGuest=${AuthService.isGuest})');
      return 0;
    }
    if (_isPushing) {
      debugPrint('🔁 SYNC: GUARD FAIL - _isPushing true');
      return 0;
    }

    _isPushing = true;
    try {
      final pending = await DatabaseService.getPendingSyncSuites();
      debugPrint('🔁 SYNC: pending suites count=${pending.length}');
      if (pending.isEmpty) {
        debugPrint('🔁 SYNC: GUARD FAIL - no pending suites');
        return 0;
      }

      int uploaded = 0;
      for (final suite in pending) {
        final suiteId = suite['id'] as int;
        final cloudId = suite['cloud_id'] as String?;

        String date;
        String? existingSerial;
        if (cloudId != null) {
          final parts = cloudId.split('/');
          date = parts[0];
          existingSerial = parts[1];
        } else {
          date = _formatDate(DateTime.parse(suite['created_at'] as String));
          existingSerial = null;
        }

        try {
          final cases = await DatabaseService.getTestCasesForSuite(suiteId);
          final suiteData = _buildSuiteDoc(suite, cases);
          suiteData['date'] = date;

          final result = await FunctionsService.pushMemberSuite(
            serialNumber: existingSerial,
            date: date,
            suiteData: suiteData,
          );
          if (result['success'] == true) {
            final actualSerial = result['serialNumber'] as String;
            final actualCloudId = cloudId ?? '$date/$actualSerial';
            await DatabaseService.markSynced(suiteId, actualCloudId);
            uploaded++;
          } else {
            debugPrint('CloudSyncService: push failed for suite $suiteId');
          }
        } catch (e) {
          debugPrint('CloudSyncService: push failed for suite $suiteId: $e');
        }
      }

      await _setLastSyncNow();
      return uploaded;
    } finally {
      _isPushing = false;
    }
  }

  static String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';

  /// Fetch one page of suite metadata from cloud and upsert to local DB.
  /// Returns the list of parsed suite maps (without test cases).
  /// [pageToken] is null for the first page.
  /// When [includeCases] is true (first page), server preloads GCS cases — they
  /// are extracted and stored locally so the first 10 suites open instantly.
  static Future<List<Map<String, dynamic>>> fetchNextSuitePage({
    int pageSize = 10,
    String? pageToken,
    bool includeCases = false,
  }) async {
    if (!_canSync) return [];
    _lastPullTime = DateTime.now();

    final result = await FunctionsService.getMemberSuitesPage(
      pageSize: pageSize,
      pageToken: pageToken,
      includeCases: includeCases,
    );
    if (result['success'] != true) return [];

    final rawSuites = result['suites'] as List? ?? [];
    final parsedSuites = <Map<String, dynamic>>[];

    for (final data in rawSuites) {
      if (data is! Map) continue;
      final suiteMap = _transformCloudSuite(data.cast<String, dynamic>());
      if (suiteMap != null) {
        final localId = await DatabaseService.upsertSuiteFromCloud(suiteMap);
        // If server included GCS cases, cache them locally for instant opening
        if (data['cases'] is List && (data['cases'] as List).isNotEmpty) {
          final cases = _parseCases(data['cases']);
          if (cases.isNotEmpty) {
            await DatabaseService.replaceAllTestCases(suiteId: localId, cases: cases);
            await DatabaseService.markSynced(localId, suiteMap['suiteId'] as String);
          }
        }
        parsedSuites.add({...suiteMap, 'id': localId});
      }
    }

    _lastPageToken = result['nextPageToken'] as String?;
    return parsedSuites;
  }

  /// Get the last page token from the most recent fetchNextSuitePage call.
  static String? get lastPageToken => _lastPageToken;
  static String? _lastPageToken;

  /// Transform server response (with _date/_serial) into cloudSuite format
  /// expected by upsertSuiteFromCloud (with suiteId).
  static Map<String, dynamic>? _transformCloudSuite(Map<String, dynamic> data) {
    try {
      final date = data['_date'] as String?;
      final serial = data['_serial'] as String?;
      if (date == null || serial == null) return null;
      return {
        'suiteId': '$date/$serial',
        'title': data['title'] ?? data['moduleName'] ?? 'Unknown',
        'moduleName': data['moduleName'] ?? '',
        'feature': data['feature'] ?? '',
        'platform': data['platform'] ?? 'Web',
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': data['updatedAt'] ?? DateTime.now().toIso8601String(),
      };
    } catch (_) {
      return null;
    }
  }

  /// Fetch test cases for a single suite from GCS and cache locally.
  /// Returns the list of parsed FinalizedTestCase, or empty on failure.
  static Future<List<FinalizedTestCase>> fetchSuiteCases({
    required String cloudId,
    required int localSuiteId,
  }) async {
    if (!_canSync) return [];
    final result = await FunctionsService.getSuiteCases(cloudId);
    if (result['success'] != true) {
      debugPrint('CloudSyncService.fetchSuiteCases: server failed for $cloudId: ${result['error']}');
      return [];
    }
    final rawCases = result['cases'];
    if (rawCases is! List) {
      debugPrint('CloudSyncService.fetchSuiteCases: cases not a List for $cloudId, got ${rawCases.runtimeType}');
      return [];
    }
    final cases = _parseCases(rawCases);
    if (cases.isEmpty) {
      debugPrint('CloudSyncService.fetchSuiteCases: _parseCases returned empty for $cloudId (raw length=${rawCases.length})');
    } else {
      debugPrint('CloudSyncService.fetchSuiteCases: loaded ${cases.length} cases for suite $localSuiteId ($cloudId)');
    }
    if (cases.isNotEmpty) {
      await DatabaseService.replaceAllTestCases(suiteId: localSuiteId, cases: cases);
      await DatabaseService.markSynced(localSuiteId, cloudId);
    }
    return cases;
  }

  /// Legacy pull — replaced by paginated fetchNextSuitePage.
  /// Kept for backward compatibility; delegates to first page fetch.
  static Future<int> pullRemoteSuites() async {
    final results = await fetchNextSuitePage(pageSize: 10, pageToken: null);
    return results.length;
  }

  static Future<void> deleteRemoteSuite(int suiteId) async {
    if (!_canSync) return;
    try {
      final cloudId = await DatabaseService.getCloudIdForSuite(suiteId);
      if (cloudId == null) return;
      await FunctionsService.deleteMemberSuite(cloudId);
    } catch (e) {
      debugPrint('CloudSyncService: delete remote failed: $e');
    }
  }

  static Future<void> processPendingDeletes() async {
    if (!_canSync) return;
    try {
      final pending = await DatabaseService.getPendingDeleteEntries();
      for (final entry in pending) {
        final id = entry['suite_id'] as int;
        final cloudId = entry['cloud_id'] as String?;
        if (cloudId != null) {
          try {
            await FunctionsService.deleteMemberSuite(cloudId);
            await DatabaseService.clearPendingDelete(id);
          } catch (e) {
            debugPrint('CloudSyncService: delete remote failed for $cloudId: $e');
          }
        } else {
          await DatabaseService.clearPendingDelete(id);
        }
      }
    } catch (e) {
      debugPrint('CloudSyncService: processPendingDeletes failed: $e');
    }
  }

  static Future<void> tryAutoSync() async {
    if (!_canSync) return;
    if (!await shouldAutoSync()) return;

    debugPrint('CloudSyncService: auto-sync triggered');
    await pushPendingSuites();
    await processPendingDeletes();
    if (_lastPullTime != null &&
        DateTime.now().difference(_lastPullTime!) < const Duration(seconds: 30)) {
      debugPrint('CloudSyncService: skipping pull — recent pull at $_lastPullTime');
      return;
    }
    // Background sync: fetch first page only (lightweight)
    await fetchNextSuitePage(pageSize: 10, pageToken: null);
  }

  static Future<SyncResult> manualSync() async {
    if (!_canSync) {
      return SyncResult(success: false, message: 'Sign in to sync across devices');
    }
    if (!NetworkGuard.isOnline) {
      return SyncResult(success: false, message: 'You are offline. Connect to the internet to sync.');
    }

    await processPendingDeletes();
    final pushed = await pushPendingSuites();

    // Manual sync: fetch all pages from cloud to fully catch up
    int pulled = 0;
    String? pageToken;
    do {
      final results = await fetchNextSuitePage(pageSize: 10, pageToken: pageToken);
      pulled += results.length;
      pageToken = _lastPageToken;
    } while (pageToken != null);

    await _setLastSyncNow();

    final parts = <String>[];
    if (pushed > 0) parts.add('$pushed suite(s) uploaded');
    if (pulled > 0) parts.add('$pulled suite(s) downloaded');
    if (parts.isEmpty) parts.add('Everything is up to date');

    return SyncResult(success: true, message: parts.join(' · '));
  }

  static Future<void> onAccountSwitch({required String oldUid, required String newUid}) async {
    await pushPendingSuites();
    await fetchNextSuitePage(pageSize: 10, pageToken: null);
  }

  static Map<String, dynamic> _buildSuiteDoc(Map<String, dynamic> suite, List<FinalizedTestCase> cases) {
    final now = DateTime.now().toIso8601String();
    return {
      'moduleName': suite['moduleName'],
      'feature': suite['feature'],
      'createdAt': suite['created_at'] ?? now,
      'updatedAt': now,
      'cases': cases.map((tc) => _encodeCase(tc)).toList(),
    };
  }

  static Map<String, dynamic> _encodeCase(FinalizedTestCase tc) {
    return {
      'id': tc.id,
      'title': tc.title,
      'preconditions': tc.preconditions,
      'testData': tc.testData,
      'steps': tc.steps.map((s) => {'action': s.action, 'data': s.data, 'expected': s.expected}).toList(),
      'expectedResult': tc.expectedResult,
      'actualResult': tc.actualResult,
      'priority': tc.priority,
      'status': tc.status,
      'type': tc.type,
      'module': tc.module,
      'feature': tc.feature,
      'platform': tc.platform,
      'source': tc.source.name,
    };
  }
  static List<FinalizedTestCase> _parseCases(dynamic rawCases) {
    if (rawCases is! List) return [];
    return rawCases.map((c) {
      if (c is! Map) return null;
      try {
        return FinalizedTestCase(
          id: c['id'] ?? '',
          title: c['title'] ?? '',
          preconditions: List<String>.from(c['preconditions'] ?? []),
          testData: c['testData'] ?? '',
          steps: (c['steps'] is List ? (c['steps'] as List) : [])
              .map((s) => TestStep(
                action: s['action'] ?? '',
                data: s['data'] ?? '',
                expected: s['expected'] ?? '',
              ))
              .toList(),
          expectedResult: c['expectedResult'] ?? '',
          actualResult: c['actualResult'] ?? '',
          priority: c['priority'] ?? 'Medium',
          status: c['status'] ?? 'Not Executed',
          type: c['type'] ?? 'Functional',
          module: c['module'] ?? '',
          feature: c['feature'] ?? '',
          platform: c['platform'] ?? 'Web',
          source: CaseSource.values.firstWhere(
            (e) => e.name == c['source'],
            orElse: () => CaseSource.ai,
          ),
        );
      } catch (_) {
        return null;
      }
    }).whereType<FinalizedTestCase>().toList();
  }
}

class SyncResult {
  final bool success;
  final String message;
  const SyncResult({required this.success, required this.message});
}
