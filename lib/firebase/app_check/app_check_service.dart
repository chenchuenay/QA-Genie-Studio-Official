import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
// ============================================================
// FILE: lib/firebase/app_check/app_check_service.dart
// ============================================================


/// ===============================================================
///
/// APP CHECK SERVICE
///
/// PURPOSE:
/// - Protect Firebase backend resources
/// - Prevent unauthorized API abuse
/// - Block unofficial app binaries
/// - Harden production infrastructure
///
/// IMPORTANT:
/// DEV MODE:
/// - Debug provider allowed
///
/// PROD MODE:
/// - Play Integrity / Apple DeviceCheck
///
/// ===============================================================
class AppCheckService {
  const AppCheckService._();

  static bool _initialized = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> initialize({required bool isProduction}) async {
    if (_initialized) {
      return;
    }

    debugPrint('🔍 APPCHECK: kDebugMode=$kDebugMode, isProduction=$isProduction');

    try {
      final androidProv =
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity;
      final appleProv =
          kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck;

      debugPrint('🔍 APPCHECK: activating android=$androidProv apple=$appleProv');

      await FirebaseAppCheck.instance.activate(
        androidProvider: androidProv,
        appleProvider: appleProv,
      );

      debugPrint('🔍 APPCHECK: activate() OK');

      _initialized = true;
      debugPrint('🔍 APPCHECK: initialized=true');
    } catch (e) {
      debugPrint('🔍 APPCHECK: activate() threw: $e');
      rethrow;
    }
  }

  // ============================================================
  // TOKEN
  // ============================================================

  static Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      final token = await FirebaseAppCheck.instance.getToken(forceRefresh);
      debugPrint('🔍 APPCHECK: getToken() OK, length=${token?.length}');
      return token;
    } catch (e) {
      debugPrint('🔍 APPCHECK: getToken() failed: $e');
      return null;
    }
  }

  // ============================================================
  // LIMITED USE TOKEN
  // ============================================================

  static Future<String?> getLimitedUseToken() async {
    try {
      return await FirebaseAppCheck.instance.getLimitedUseToken();
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // HEALTH
  // ============================================================

  static Future<bool> isAvailable() async {
    return _initialized;
  }

  // ============================================================
  // DEBUG
  // ============================================================

  static Map<String, dynamic> diagnostics() {
    return {
      'initialized': _initialized,
      'platform': defaultTargetPlatform.name,
    };
  }
}
