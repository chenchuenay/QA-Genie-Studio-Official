import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/app.dart';
import 'package:qa_genie/app_config.dart';
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
    if (AppConfig.isDev) {
      await Firebase.initializeApp(options: _devFirebaseOptions);
    } else {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    }
    await AppCheckService.initialize();
    await MobileAds.instance.initialize();
    ForensicsProvider.init(ForensicsServiceProd());
  } catch (e) {
    debugPrint("Startup critical error: $e");
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

const FirebaseOptions _devFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyClNIMloB5GvcDuxdllXlh41JSj0aW26EY',
  appId: '1:113750340081:android:64a9e770deaaec18677add',
  messagingSenderId: '113750340081',
  projectId: 'qa-genie-ai-dev',
  storageBucket: 'qa-genie-ai-dev.firebasestorage.app',
);
