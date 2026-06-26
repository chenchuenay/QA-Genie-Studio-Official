import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:qa_genie/app_config.dart';

class AppCheckService {
  const AppCheckService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('🔍 APPCHECK: isDev=${AppConfig.isDev}');

    try {
      if (AppConfig.isDev) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
      } else {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
        );
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
