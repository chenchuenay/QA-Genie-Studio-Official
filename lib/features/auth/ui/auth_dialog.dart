import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/features/legal/ui/terms_privacy_policy.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/firebase/analytics/analytics_service.dart';

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
  if (msg.contains('network') || msg.contains('Network')) return 'Please check your internet and try again.';
  if (msg.contains('unavailable') || msg.contains('Unavailable')) return 'Please check your internet and try again.';
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
  String? _errorMessage;

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
    try {
      unawaited(AnalyticsService.logDebug(message: 'handleContinueWithGoogle: calling linkWithGoogle'));
      await AuthService.linkWithGoogle();

      // Pull remote suites (if any)
      await AuthService.completePostLoginFlow();

      if (!mounted) return;

      // Welcome confirmation
      final user = AuthService.currentUser;
      String displayName = user?.displayName ?? '';
      if (displayName.isEmpty && user != null) {
        for (final info in user.providerData) {
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
      unawaited(AnalyticsService.logDebug(message: 'handleContinueWithGoogle: CAUGHT $e'));
      setState(() {
        _errorMessage = _friendlyAuthError(e);
        _isLoading = false;
      });
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
    if (!await NetworkGuard.ensureProductionOnline(context)) return;
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
    final user = AuthService.currentUser;
    final isNewUser = user == null;
    final displayName = user?.displayName ?? '';
    final welcomeText = !isNewUser && displayName.isNotEmpty
        ? 'Welcome back, ${displayName.split(' ').first}'
        : (isNewUser ? 'Welcome to QAG' : 'Welcome back to QAG');

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
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
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _isGuestLoading ? null : _handleContinueWithGoogle,
                    icon: _isLoading 
                      ? const SizedBox.shrink() 
                      : const Icon(Icons.g_mobiledata, color: Colors.black, size: 32),
                    label: const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                if (widget.showGuestButton) ...[
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
                ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsPrivacyPolicyScreen()),
                    );
                  },
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
                          text: 'Terms & Privacy Policy',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none, // Explicitly no underline
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
