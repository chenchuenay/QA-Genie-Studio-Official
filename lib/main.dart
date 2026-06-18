import 'package:flutter/material.dart';
import 'package:qa_genie/app/app.dart';
import 'firebase/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/firebase/app_check/app_check_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    await AppCheckService.initialize(isProduction: AppConfig.isProduction);
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint("Startup critical error: $e");
  }

  FlutterError.onError = (details) {
    debugPrint('🔥 FlutterError: ${details.exception}');
    debugPrint('   stack: ${details.stack}');
  };
  runApp(const QaGenieApp());

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!AppConfig.isProduction) {
      try {
        final prefs = await AppConfig.sharedPrefs;
        AppConfig.initTestProMode(prefs.getBool('testProMode') ?? false);
      } catch (_) {}
    }

    try {
      await DatabaseService.syncPendingReports();
    } catch (_) {}
  });
}
