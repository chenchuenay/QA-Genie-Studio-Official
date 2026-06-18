import 'package:flutter/material.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/features/monetization/ads/ad_manager.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/features/update/logic/update_manager.dart';
import 'package:qa_genie/features/update/ui/update_required_screen.dart';
import 'package:qa_genie/shared/dialogs/guidelines_dialog.dart';
import 'package:qa_genie/shared/navigation/main_screen.dart';
import 'package:qa_genie/features/auth/ui/auth_dialog.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/engine/prompts/prompt_cache_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showGuidelines = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _initGuestAuth(),
      UsageManager.getDashboardData(),
      PromptCacheManager.warmup().catchError((_) {}),
      NetworkGuard.initialize().catchError((_) {}),
    ]);
    // Fire ad preload in background — don't block navigation
    AdManager().loadRewardedAd().catchError((_) {});

    final check = await UpdateManager.checkForUpdate().timeout(
      const Duration(seconds: 1),
      onTimeout: () => UpdateManager.noUpdate(),
    );
    if (!mounted) return;
    if (check.updateRequired) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => UpdateRequiredScreen(check: check),
        ),
      );
      return;
    }

    final user = AuthService.currentUser;
    final identity = user?.uid ?? 'guest_default';
    await DatabaseService.initDatabase(identity);
    if (!mounted) return;

    final prefs = await AppConfig.sharedPrefs;
    final firstLaunch = prefs.getBool('first_launch_completed') ?? false;

    if (!firstLaunch) {
      await showBlurredDialog(
        context,
        builder: (ctx) => const AuthDialog(showGuestButton: true),
      );
      if (!mounted) return;
      await prefs.setBool('first_launch_completed', true);

      if (mounted) {
        final neverShow = prefs.getBool('never_show_guidelines') ?? false;
        final alreadyShown = prefs.getBool('first_launch_guidelines_shown') ?? false;
        if (!neverShow && !alreadyShown) {
          await prefs.setBool('first_launch_guidelines_shown', true);
          if (mounted) {
            await showBlurredDialog(
              context,
              builder: (_) => const GuidelinesDialog(
                showNeverAsk: true,
                autoScroll: true,
                showTourButton: false,
              ),
            );
            _showGuidelines = true;
          }
        }
      }
    }

    if (!mounted) return;
    MainScreenState.shouldAutoStartTour = _showGuidelines;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  Future<void> _initGuestAuth() async {
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await AuthService.signInAsGuest();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 144, height: 144),
            const SizedBox(height: 16),
            const Text(
              'QA Genie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
