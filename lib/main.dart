import 'package:flutter/material.dart';
import 'package:qa_genie/app/app.dart';
import 'firebase/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/engine/prompts/prompt_cache_manager.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/firebase/app_check/app_check_service.dart';

Future<void> main() async {
  // 🚀 NATURAL SPEED FLOW: Ensure splash screen stays until fully ready
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Ads
  final adsStatus = await MobileAds.instance.initialize();
  adsStatus.adapterStatuses.forEach((key, value) {
    debugPrint('AdMob Adapter $key: ${value.state}');
  });

  // Load Environment
  try {
    await dotenv.load(fileName: kReleaseMode ? ".env.prod" : ".env.dev");
  } catch (_) {}

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

    // 🛡️ SECURITY: Protect production resources
    await AppCheckService.initialize(
      isProduction: AppConfig.isProduction,
    );
  } catch (e) {
    debugPrint("Startup critical error: $e");
  }

  // Persistent Guest Initialization
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await AuthService.signInAsGuest();
    }
  } catch (e) {
    debugPrint("🔴 Auth initialization failed: $e");
    // Continue anyway to allow app to boot to UI
  }

  // Cache prompts
  await PromptCacheManager.warmup();

  if (!AppConfig.isProduction) {
    final prefs = await SharedPreferences.getInstance();
    AppConfig.testProMode = prefs.getBool('testProMode') ?? false;
  }

  runApp(const QaGenieApp());
}
