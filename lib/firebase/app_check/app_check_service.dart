import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
// ============================================================
// FILE: lib/firebase/app_check/app_check_service.dart
// ============================================================


class AppCheckService {
  const AppCheckService._();

  static bool _initialized = false;

  static const _channel = MethodChannel('com.enaykumar.qagenie/app_check');

  static Future<void> initialize({required bool isProduction}) async {
    if (_initialized) return;

    debugPrint('🔍 APPCHECK: isProduction=$isProduction');

    try {
      if (isProduction) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
        );
      } else {
        // Activate debug provider first (so the SDK has a provider registered),
        // then immediately override it with a custom provider that returns
        // fake tokens — the server has enforceAppCheck disabled for dev, so
        // it accepts any token.
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        await _channel.invokeMethod('installDevAppCheckProvider');
      }
      _initialized = true;
      debugPrint('🔍 APPCHECK: initialized');
    } catch (e) {
      debugPrint('🔍 APPCHECK: activate() threw: $e');
      rethrow;
    }
  }

  static Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      final token = await FirebaseAppCheck.instance.getToken(forceRefresh);
      return token;
    } catch (e) {
      debugPrint('🔍 APPCHECK: getToken() failed: $e');
      return null;
    }
  }
}
