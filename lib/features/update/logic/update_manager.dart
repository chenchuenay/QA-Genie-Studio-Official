import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';

class UpdateCheckResult {
  final bool updateRequired;
  final String latestVersion;
  final String latestBuild;
  final String blockBelowBuild;
  final String updateUrl;
  final int dismissCount;
  final bool blocked;

  UpdateCheckResult({
    required this.updateRequired,
    required this.latestVersion,
    required this.latestBuild,
    required this.blockBelowBuild,
    required this.updateUrl,
    required this.dismissCount,
    required this.blocked,
  });
}

class UpdateManager {
  static const String _versionDocPath = 'app_config/version';
  static const int _maxDismissals = 3;

  static Future<UpdateCheckResult> checkForUpdate() async {
    final package = await PackageInfo.fromPlatform();
    final currentVersion = package.version;

    try {
      final doc = await FirebaseFirestore.instance
          .doc(_versionDocPath)
          .get();

      if (!doc.exists) {
        return noUpdate();
      }

      final data = doc.data()!;
      final latestVersion = data['latestVersion'] as String? ?? currentVersion;
      final latestBuild = data['latestBuild'] as String? ?? currentVersion;
      final blockBelowBuild = data['blockBelowBuild'] as String? ?? '';
      final updateUrl = data['updateUrl'] as String? ??
          'https://play.google.com/store/apps/details?id=com.enaykumar.qagenie';

      if (_semverCompare(currentVersion, blockBelowBuild) < 0) {
        final isGuest = AuthService.isGuest;
        int dismissCount = 0;
        if (!isGuest && AuthService.currentUser != null) {
          try {
            final result = await FunctionsService.call(
              functionName: 'getUserDashboard',
              payload: {'type': 'user'},
            );
            final metrics = result['metrics'] as Map?;
            dismissCount = (metrics?['updateDismissals'] as int?) ?? 0;
          } catch (e) {
            debugPrint('UpdateManager: failed to read dismissals: $e');
            dismissCount = await _localDismissCount();
          }
        } else {
          dismissCount = await _localDismissCount();
        }

        return UpdateCheckResult(
          updateRequired: true,
          latestVersion: latestVersion,
          latestBuild: latestBuild,
          blockBelowBuild: blockBelowBuild,
          updateUrl: updateUrl,
          dismissCount: dismissCount,
          blocked: dismissCount >= _maxDismissals,
        );
      }

      return noUpdate();
    } catch (e) {
      debugPrint('UpdateManager: check failed: $e');
      return noUpdate();
    }
  }

  static Future<void> recordDismissal() async {
    final uid = AuthService.currentUser?.uid;
    if (uid != null && !AuthService.isGuest) {
      try {
        await FunctionsService.call(functionName: 'recordUpdateDismissal');
      } catch (e) {
        debugPrint('UpdateManager: failed to record dismissal: $e');
        await _incrementLocalDismiss();
      }
    } else {
      await _incrementLocalDismiss();
    }
  }

  static Future<int> _localDismissCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('update_dismiss_count') ?? 0;
  }

  static Future<void> _incrementLocalDismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('update_dismiss_count') ?? 0) + 1;
    await prefs.setInt('update_dismiss_count', count);
  }

  static int _semverCompare(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal != bVal) return aVal - bVal;
    }
    return 0;
  }

  static UpdateCheckResult noUpdate() {
    return UpdateCheckResult(
      updateRequired: false,
      latestVersion: '',
      latestBuild: '',
      blockBelowBuild: '',
      updateUrl: '',
      dismissCount: 0,
      blocked: false,
    );
  }
}
