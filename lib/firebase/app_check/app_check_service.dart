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

    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: isProduction
            ? AndroidProvider.playIntegrity
            : AndroidProvider.debug,

        appleProvider: isProduction
            ? AppleProvider.deviceCheck
            : AppleProvider.debug,
      );

      _initialized = true;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // TOKEN
  // ============================================================

  static Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      return await FirebaseAppCheck.instance.getToken(forceRefresh);
    } catch (_) {
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
    try {
      final token = await getToken();

      return token != null && token.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
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
