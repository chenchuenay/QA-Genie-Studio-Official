import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/features/legal/ui/terms_privacy_policy.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';

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
    if (_isLoading) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    if (!await NetworkGuard.ensureProductionOnline(context)) return;
    try {
      await AuthService.linkWithGoogle();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyAuthError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleContinueAsGuest() async {
    if (_isGuestLoading) return;
    if (!mounted) return;
    setState(() {
      _isGuestLoading = true;
      _errorMessage = null;
    });
    if (!await NetworkGuard.ensureProductionOnline(context)) return;
    try {
      await AuthService.signInAsGuest();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
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
                    label: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                          )
                        : const Text(
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
                      child: _isGuestLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                            )
                          : const Text(
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
