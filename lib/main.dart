import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/app.dart';
import 'firebase/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qa_genie/core/forensics/forensics_provider.dart';
import 'package:qa_genie/core/forensics/forensics_service_prod.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/firebase/app_check/app_check_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    await AppCheckService.initialize(isProduction: true);
    await MobileAds.instance.initialize();
    ForensicsProvider.init(ForensicsServiceProd());
  } catch (e) {
    debugPrint("Startup critical error: $e");
    // Still init forensics even if Firebase fails
    try { ForensicsProvider.init(ForensicsServiceProd()); } catch (_) {}
  }

  FlutterError.onError = (details) {
    debugPrint('🔥 FlutterError: ${details.exception}');
    debugPrint('   stack: ${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔥 PlatformDispatcher.onError: $error');
    debugPrint('   stack: $stack');
    return true;
  };
  runApp(const QaGenieApp());

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await DatabaseService.syncPendingReports();
    } catch (_) {}
  });
}
