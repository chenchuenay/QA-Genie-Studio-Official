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

class CloudSyncService {
  static const _lastSyncKey = 'cloud_last_sync_ms';
  static const _syncIntervalHours = 24;
  static bool _isPushing = false;
  static bool _isPulling = false;
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
    if (!_canSync) return 0;
    if (_isPushing) return 0;

    _isPushing = true;
    try {
      final pending = await DatabaseService.getPendingSyncSuites();
      if (pending.isEmpty) return 0;

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

  static Future<int> pullRemoteSuites() async {
    if (!_canSync) return 0;
    if (_isPulling) return 0;

    _isPulling = true;
    _lastPullTime = DateTime.now();
    try {
      final suites = await FunctionsService.getMemberSuites();
      int pulled = 0;
      for (final data in suites) {
        final suiteMap = _parseSuiteDoc(data['suiteId'] as String, data);
        if (suiteMap != null) {
          await DatabaseService.upsertSuiteFromCloud(suiteMap);
          final localId = await _getLocalSuiteId(data['suiteId'] as String);
          if (localId != null) {
            final cases = _parseCases(data['cases']);
            if (cases.isNotEmpty) {
              await DatabaseService.replaceAllTestCases(suiteId: localId, cases: cases);
              await DatabaseService.markSynced(localId, data['suiteId'] as String);
            }
          }
          pulled++;
        }
      }
      await _setLastSyncNow();
      return pulled;
    } catch (e) {
      debugPrint('CloudSyncService: pull failed: $e');
      return 0;
    } finally {
      _isPulling = false;
    }
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
      final pendingIds = await DatabaseService.getPendingDeleteSuiteIds();
      for (final id in pendingIds) {
        await deleteRemoteSuite(id);
        await DatabaseService.clearPendingDelete(id);
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
    await pullRemoteSuites();
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
    final pulled = await pullRemoteSuites();

    final parts = <String>[];
    if (pushed > 0) parts.add('$pushed suite(s) uploaded');
    if (pulled > 0) parts.add('$pulled suite(s) downloaded');
    if (parts.isEmpty) parts.add('Everything is up to date');

    return SyncResult(success: true, message: parts.join(' · '));
  }

  static Future<void> onAccountSwitch({required String oldUid, required String newUid}) async {
    await pushPendingSuites();
    await pullRemoteSuites();
  }

  static Future<int?> _getLocalSuiteId(String cloudId) async {
    final db = await DatabaseService.db;
    final rows = await db.query('suites',
        columns: ['id'], where: 'cloud_id = ?', whereArgs: [cloudId]);
    if (rows.isEmpty) return null;
    return rows.first['id'] as int;
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

  static Map<String, dynamic>? _parseSuiteDoc(String docId, Map<String, dynamic> data) {
    try {
      return {
        'suiteId': docId,
        'title': data['title'] ?? data['moduleName'] ?? 'Unknown',
        'moduleName': data['moduleName'] ?? '',
        'feature': data['feature'] ?? '',
        'platform': data['platform'] ?? 'Web',
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': data['updatedAt'] ?? DateTime.now().toIso8601String(),
        'cases': data['cases'] ?? [],
      };
    } catch (_) {
      return null;
    }
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
