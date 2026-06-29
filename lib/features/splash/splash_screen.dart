import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/features/monetization/ads/ad_manager.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/shared/navigation/main_screen.dart';
import 'package:qa_genie/features/auth/ui/auth_dialog.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/core/utils/device_utils.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/core/cloud/cloud_sync_service.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
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
    try {
    final prefs = await AppConfig.sharedPrefs;
    final firstLaunch = prefs.getBool('first_launch_completed') ?? false;

    // Initialize DB early so post-login flows (suite pull) can access it
    try {
      final identity = await DeviceUtils.getUniqueId()
          .timeout(const Duration(seconds: 10), onTimeout: () => 'fallback_${DateTime.now().millisecondsSinceEpoch}');
      await DatabaseService.initDatabase(identity);
    } catch (e) {
      debugPrint('⚠️ Splash: DB init failed — $e');
    }

    // Wait for Firebase Auth to restore any persisted session before checking currentUser
    try {
      await FirebaseAuth.instance.authStateChanges().first
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Timeout — proceed with current auth state
    }

    if (!firstLaunch) {
      await showBlurredDialog(
        context,
        barrierDismissible: false,
        builder: (ctx) => const AuthDialog(showGuestButton: true),
      );
      if (!mounted) return;
      await prefs.setBool('first_launch_completed', true);

      if (mounted) {
        _showGuidelines = true;
      }
    } else if (FirebaseAuth.instance.currentUser == null) {
      // No persisted auth session — check for post-sign-out guest creation flag
      final pendingGuest = prefs.getBool('pending_guest_creation') ?? false;
      if (pendingGuest) {
        await prefs.remove('pending_guest_creation');
        debugPrint('⚠️ Splash: pending_guest_creation flag set — attempting auto-create');
        // Retry up to 3 times with backoff for transient cloud function errors
        for (int i = 0; i < 3; i++) {
          try {
            await AuthService.signInAsGuest(forceReturning: true, caller: 'splash_init');
            debugPrint('⚠️ Splash: post-sign-out guest created successfully on attempt ${i + 1}');
            break;
          } catch (e) {
            debugPrint('⚠️ Splash: post-sign-out guest creation attempt ${i + 1} failed — $e');
            if (i < 2) await Future.delayed(Duration(seconds: (i + 1)));
          }
        }
      }
      // If still not signed in after auto-create attempt, show auth dialog
      if (FirebaseAuth.instance.currentUser == null) {
        await showBlurredDialog(
          context,
          barrierDismissible: false,
          builder: (ctx) => const AuthDialog(showGuestButton: true),
        );
        if (!mounted) return;
      }
    }

    // Session conflict check for already-signed-in members (cold start)
    if (FirebaseAuth.instance.currentUser != null && !AuthService.isGuest) {
      final deviceId = await DeviceUtils.getUniqueId();
      Map<String, dynamic> sessionResult = {'conflict': false};
      try {
        sessionResult = await FunctionsService.registerSession(
          deviceId: deviceId,
          force: false,
        );
      } catch (e) {
        debugPrint('⚠️ Splash: registerSession threw — $e');
      }
      if (sessionResult['error'] != null) {
        debugPrint('⚠️ Splash: registerSession error — ${sessionResult['error']}');
        sessionResult = {'conflict': false};
      }
      if (sessionResult['conflict'] == true) {
        if (!mounted) return;
        final choice = await showBlurredDialog<String>(
          context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Already Signed In',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Signing in here logs out the other device.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'no'),
                child: const Text('No', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, 'okay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Okay'),
              ),
            ],
          ),
        );

        if (choice == 'no') {
          await AuthService.signOut();
          if (!mounted) return;
          await showBlurredDialog(
            context,
            barrierDismissible: false,
            builder: (ctx) => const AuthDialog(showGuestButton: true),
          );
          if (!mounted) return;
        } else {
          await FunctionsService.registerSession(
            deviceId: deviceId,
            force: true,
          );
        }
      }
    }

    // Navigate immediately — splash should be invisible to the member.
    if (!mounted) return;
    try {
      MainScreenState.shouldAutoStartTour = _showGuidelines;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      debugPrint('⚠️ Splash: navigation failed — $e');
    }

    // All network / async init work fires in the background after navigation.
    unawaited(UsageManager.getDashboardData());
    unawaited(PromptCacheManager.warmup().catchError((_) {}));
    unawaited(NetworkGuard.initialize().catchError((_) {}));
    unawaited(AdManager().loadRewardedAd().catchError((_) {}));
    unawaited(_backgroundInit());
    } catch (e) {
      debugPrint('⚠️ Splash: _init top-level error — $e');
      if (mounted) {
        MainScreenState.shouldAutoStartTour = false;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  Future<void> _backgroundInit() async {
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
