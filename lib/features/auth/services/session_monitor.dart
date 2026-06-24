import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/core/utils/device_utils.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/features/splash/splash_screen.dart';

class SessionMonitor {
  static StreamSubscription<DocumentSnapshot>? _subscription;
  static String? _currentDeviceId;
  static bool _isActive = false;

  static Future<void> start(BuildContext context) async {
    if (_isActive) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || AuthService.isGuest) return;
    final email = user.email;
    if (email == null) return;

    _currentDeviceId = await DeviceUtils.getUniqueId();

    final doc = await FirebaseFirestore.instance
        .collection('memberProfiles')
        .doc(email)
        .get();
    if (!doc.exists) return;

    final profileData = doc.data()!;
    final profileUid = profileData['uid'] as String?;
    if (profileUid == null) return;

    final tier = profileData['subscription']?['planType'] == 'pro' ? 'pro' : 'core';

    _isActive = true;
    _subscription = FirebaseFirestore.instance
        .collection('memberData')
        .doc(tier)
        .collection(profileUid)
        .doc('_session')
        .snapshots()
        .listen(
      (snapshot) {
        if (!_isActive || !snapshot.exists) return;
        final storedDeviceId = snapshot.data()?['deviceId'] as String?;
        if (storedDeviceId != null && storedDeviceId != _currentDeviceId) {
          _handleConflict(context);
        }
      },
      onError: (e) {
        debugPrint('SessionMonitor error: $e');
        stop();
      },
    );
  }

  static void stop() {
    _isActive = false;
    _subscription?.cancel();
    _subscription = null;
  }

  static Future<void> _handleConflict(BuildContext context) async {
    stop();
    if (!context.mounted) return;
    await showBlurredDialog(
      context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Signed in on another device',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your account was used to sign in on another device. '
              'You have been signed out.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    await AuthService.hardSignOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }
}
