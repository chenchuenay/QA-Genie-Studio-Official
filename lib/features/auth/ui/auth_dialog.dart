import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/core/utils/device_utils.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/firebase/analytics/analytics_service.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/features/legal/data/legal_documents.dart';

String _friendlyAuthError(dynamic e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'user-disabled': return 'This account has been disabled.';
      case 'operation-not-allowed': return 'Please try the other sign-in method.';
      case 'account-exists-with-different-credential': return 'An account already exists with a different sign-in method.';
      case 'network-request-failed': return 'Please check your internet and try again.';
      case 'too-many-requests': return 'Please wait a moment and try again.';
      case 'invalid-credential': return 'Please try again.';
      case 'requires-recent-login': return 'Please sign out and sign in again.';
      case 'permission-denied': return 'This Google account was recently deleted and cannot be used again for 24 hours. Please try a different account or come back later.';
      default: return 'Please try again.';
    }
  }
  final msg = e.toString().replaceFirst('Exception: ', '');
  if (msg.contains('GUARD_BLOCK')) return 'Please wait and try again.';
  if (msg.contains('Failed to get guest token')) {
    // Extract error code for debugging — shows e.g. "(rate limited)" in the message
    final err = msg.contains(': ') ? msg.split(': ').last.trim() : '';
    return 'Unable to create guest session${err.isNotEmpty ? ' ($err)' : ''}. Please try again.';
  }
  if (msg.contains('network') || msg.contains('Network')) return 'Please check your internet and try again.';
  if (msg.contains('unavailable') || msg.contains('Unavailable')) return 'Please check your internet and try again.';
  if (msg.contains('resource-exhausted')) return 'Too many attempts. Please wait and try again.';
  return 'Please try again.';
}

class AuthDialog extends StatefulWidget {
  final bool showGuestButton;
  const AuthDialog({super.key, this.showGuestButton = true});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool _isLoading = false;
  bool _isGuestLoading = false;
  bool _forceGoogleOnly = false;
  String? _errorMessage;
  Timer? _dotTimer;
  int _dotCount = 0;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }

  void _startConnectingAnimation() {
    _dotCount = 0;
    _dotTimer?.cancel();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() => _dotCount = (_dotCount + 1) % 4);
    });
  }

  void _resetForceGoogleOnly() {
    setState(() {
      _forceGoogleOnly = false;
      _errorMessage = null;
    });
  }

  Future<void> _handleContinueWithGoogle() async {
    unawaited(AnalyticsService.logDebug(message: 'handleContinueWithGoogle: ENTER'));
    if (_isLoading) {
      unawaited(AnalyticsService.logDebug(message: 'handleContinueWithGoogle: SKIP already loading'));
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _startConnectingAnimation();
    if (!await NetworkGuard.ensureProductionOnline(context)) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      // Step 1: Google sign-in (manual, to get email before linking)
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Step 2: Check email cooldown
      try {
        await FunctionsService.call(
          functionName: 'checkEmailCooldown',
          payload: {'email': googleAccount.email},
          throwOnError: true,
        );
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'permission-denied') {
          throw FirebaseAuthException(
            code: 'permission-denied',
            message: 'This Google account was recently deleted and cannot be used again for 24 hours.',
          );
        }
        rethrow;
      }

      // Step 3: Check session conflict BEFORE linking
      final deviceId = await DeviceUtils.getUniqueId();
      final sessionCheck = await FunctionsService.checkSessionByEmail(
        email: googleAccount.email,
        deviceId: deviceId,
      );
      if (sessionCheck['error'] != null) {
        debugPrint('⚠️ Auth: checkSessionByEmail error — ${sessionCheck['error']}');
        sessionCheck['conflict'] = false;
      }

      if (sessionCheck['conflict'] == true) {
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
          await _googleSignIn.signOut();
          setState(() {
            _forceGoogleOnly = true;
            _isLoading = false;
          });
          return;
        }
      }

      // Step 4: Full Google link (pass pre-signed-in account)
      await AuthService.linkWithGoogle(preSignedInAccount: googleAccount);

      // Step 5: Register session
      final hadConflict = sessionCheck['conflict'] == true;
      await FunctionsService.registerSession(
        deviceId: deviceId,
        force: hadConflict,
      );

      // Pull remote suites (if any)
      await AuthService.completePostLoginFlow();

      if (!mounted) return;
      _dotTimer?.cancel();

      // Welcome confirmation
      final member = AuthService.currentMember;
      String displayName = member?.displayName ?? '';
      if (displayName.isEmpty && member != null) {
        for (final info in member.providerData) {
          if (info.providerId == 'google.com' && (info.displayName?.isNotEmpty == true)) {
            displayName = info.displayName!;
            break;
          }
        }
      }
      final greeting = displayName.isNotEmpty
          ? 'Welcome, ${displayName.split(' ').first}!'
          : 'Welcome!';
      await showBlurredDialog(
        context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.accent, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                greeting,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'You\'re now signed in with Google.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Let\'s Go', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
      unawaited(AnalyticsService.logDebug(message: 'handleContinueWithGoogle: SUCCESS auth dialog popped'));
    } catch (e) {
      if (!mounted) return;
      _dotTimer?.cancel();
      // Clear Google cached account so next tap shows the account picker
      await _googleSignIn.signOut();
      unawaited(AnalyticsService.logDebug(message: 'handleContinueWithGoogle: CAUGHT $e'));
      if (e is FirebaseAuthException && e.code == 'permission-denied') {
        await showBlurredDialog(
          context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Account Cooldown',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'This Google account was recently deleted and cannot be used again for 24 hours. Please try a different account or come back later.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
        setState(() {
          _errorMessage = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = _friendlyAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleContinueAsGuest() async {
    unawaited(AnalyticsService.logDebug(message: 'handleContinueAsGuest: ENTER'));
    if (_isGuestLoading) {
      unawaited(AnalyticsService.logDebug(message: 'handleContinueAsGuest: SKIP already loading'));
      return;
    }
    if (!mounted) return;
    setState(() {
      _isGuestLoading = true;
      _errorMessage = null;
    });
    if (!await NetworkGuard.ensureProductionOnline(context)) {
      if (mounted) setState(() => _isGuestLoading = false);
      return;
    }
    try {
      unawaited(AnalyticsService.logDebug(message: 'handleContinueAsGuest: calling signInAsGuest'));
      await AuthService.signInAsGuest(caller: 'guest_button');
      if (!mounted) return;
      Navigator.pop(context);
      unawaited(AnalyticsService.logDebug(message: 'handleContinueAsGuest: SUCCESS'));
    } catch (e) {
      if (!mounted) return;
      unawaited(AnalyticsService.logDebug(message: 'handleContinueAsGuest: CAUGHT $e'));
      setState(() {
        _errorMessage = _friendlyAuthError(e);
        _isGuestLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = AuthService.currentMember;
    final isNewMember = member == null;
    final displayName = member?.displayName ?? '';
    final welcomeText = !isNewMember && displayName.isNotEmpty
        ? 'Welcome back, ${displayName.split(' ').first}'
        : (isNewMember ? 'Welcome to QA Genie' : 'Welcome back to QA Genie');

    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
        child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 54,
                    width: 54,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  welcomeText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AI-Powered Test Flow Engine',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading || _isGuestLoading ? null : _handleContinueWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading
                          ? AppColors.accent.withOpacity(0.7)
                          : AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: _isLoading ? 0.0 : 1.0,
                          child: SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_mobiledata, color: Colors.black, size: 32),
                                  SizedBox(width: 8),
                                  Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: _isLoading ? 1.0 : 0.0,
                          child: SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.g_mobiledata, color: Colors.black, size: 32),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Connecting to Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '${'.' * _dotCount}',
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.showGuestButton && !_forceGoogleOnly) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: _isLoading || _isGuestLoading ? null : _handleContinueAsGuest,
                      child: const Text(
                              'Continue as Guest',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                            ),
                    ),
                  ),
                ] else if (_forceGoogleOnly) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Use a different Google account to continue.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse(LegalDocuments.privacyPolicyUrl)),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(fontSize: 11),
                      children: [
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                        TextSpan(
                          text: 'Privacy, Terms of Service',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      );
  }
}
