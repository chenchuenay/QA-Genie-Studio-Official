import 'package:flutter/material.dart';
import 'package:qa_genie/app/app.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/core/forensics/forensics_provider.dart';
import 'package:qa_genie/core/forensics/forensics_service_dev.dart';
import 'package:qa_genie/engine/forensics/pipeline_observer.dart';
import 'package:qa_genie/features/monetization/ui/test_mode_screen.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'firebase/firebase_options_dev.dart' as dev_fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qa_genie/firebase/app_check/app_check_service.dart';

class DevPipelineObserver implements PipelineObserver {
  @override
  void onStageEvent(String category, Map<String, dynamic> data) {
    debugPrint('[PIPELINE] $category: $data');
  }

  @override
  void onTraceEvent(String message) {
    debugPrint('[TRACE] $message');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: dev_fb.DefaultFirebaseOptionsDev.android);
    await AppCheckService.initialize(isProduction: AppConfig.isProduction);
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint("Startup critical error: $e");
  }

  ForensicsProvider.init(ForensicsServiceDev());
  PipelineForensics.setObserver(DevPipelineObserver());

  FlutterError.onError = (details) {
    debugPrint('🔥 FlutterError: ${details.exception}');
    debugPrint('   stack: ${details.stack}');
  };

  final devActions = <Widget>[
    Builder(builder: (context) => IconButton(
        icon: const Icon(Icons.science, color: AppColors.accent),
        tooltip: 'Test Mode',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TestModeScreen(
              onRestart: () => QaGenieApp.restartApp(context),
            ),
          ),
        ),
      ),
    ),
  ];

  QaGenieApp.setAppBarActions(devActions);
  runApp(const QaGenieApp());

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final prefs = await AppConfig.sharedPrefs;
      AppConfig.initTestProMode(prefs.getBool('testProMode') ?? false);
    } catch (_) {}

    try {
      await DatabaseService.syncPendingReports();
    } catch (_) {}
  });
}
