import 'package:flutter/material.dart';
import 'package:qa_genie/app/app.dart';
import 'firebase/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/engine/prompts/prompt_cache_manager.dart';

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
  } catch (e) {
    debugPrint("Startup critical error: $e");
  }

  // Cache prompts
  await PromptCacheManager.warmup();

  if (!AppConfig.isProduction) {
    final prefs = await SharedPreferences.getInstance();
    AppConfig.testProMode = prefs.getBool('testProMode') ?? false;
  }

  runApp(const QaGenieApp());
}
