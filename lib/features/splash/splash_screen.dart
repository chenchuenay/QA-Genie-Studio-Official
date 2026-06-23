import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/features/monetization/ads/ad_manager.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/shared/dialogs/guidelines_dialog.dart';
import 'package:qa_genie/shared/navigation/main_screen.dart';
import 'package:qa_genie/features/auth/ui/auth_dialog.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/core/utils/device_utils.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/core/cloud/cloud_sync_service.dart';
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
    final prefs = await AppConfig.sharedPrefs;
    final firstLaunch = prefs.getBool('first_launch_completed') ?? false;

    if (!firstLaunch) {
      await showBlurredDialog(
        context,
        barrierDismissible: false,
        builder: (ctx) => const AuthDialog(showGuestButton: true),
      );
      if (!mounted) return;
      await prefs.setBool('first_launch_completed', true);

      if (mounted) {
        final neverShow = prefs.getBool('never_show_guidelines') ?? false;
        final alreadyShown =
            prefs.getBool('first_launch_guidelines_shown') ?? false;
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
    } else if (FirebaseAuth.instance.currentUser == null) {
      // No persisted auth session — show auth dialog instead of auto-creating a guest.
      await showBlurredDialog(
        context,
        barrierDismissible: false,
        builder: (ctx) => const AuthDialog(showGuestButton: true),
      );
      if (!mounted) return;
    }

    // Navigate immediately — splash should be invisible to the member.
    if (!mounted) return;
    MainScreenState.shouldAutoStartTour = _showGuidelines;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );

    // All network / async init work fires in the background after navigation.
    unawaited(UsageManager.getDashboardData());
    unawaited(PromptCacheManager.warmup().catchError((_) {}));
    unawaited(NetworkGuard.initialize().catchError((_) {}));
    unawaited(AdManager().loadRewardedAd().catchError((_) {}));
    unawaited(_backgroundInit());
  }

  Future<void> _backgroundInit() async {
    final identity = await DeviceUtils.getUniqueId();
    await DatabaseService.initDatabase(identity);
    // One-time migration from legacy UID-based identity to device-level identity
    final oldUid = AuthService.currentMember?.uid ?? 'guest_default';
    await DatabaseService.migrateDataToCurrentDb(oldUid);

    if (AuthService.currentMember != null && !AuthService.isGuest) {
      unawaited(CloudSyncService.tryAutoSync().catchError((_) {}));
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
