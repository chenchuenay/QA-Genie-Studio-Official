import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qa_genie/app/theme/premium_theme.dart';
import 'package:qa_genie/core/error/ui_error_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();

  final _passCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      final provider = GoogleAuthProvider();

      await FirebaseAuth.instance.signInWithProvider(provider);
    } catch (e, stack) {
      UiErrorService.logAndShow(
        context: context,
        source: ErrorSource.auth,
        screen: 'AuthScreen',
        stage: ErrorStage.authentication,
        severity: ErrorSeverity.error,
        userMessage: 'Google sign-in failed',
        error: e,
        stack: stack,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (_loading) return;

    FocusScope.of(context).unfocus();

    final email = _emailCtrl.text.trim();

    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email and password are required'),
          backgroundColor: AppColors.error,
        ),
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e, stack) {
      UiErrorService.logAndShow(
        context: context,
        source: ErrorSource.auth,
        screen: 'AuthScreen',
        stage: ErrorStage.authentication,
        severity: ErrorSeverity.error,
        userMessage: e.message ?? 'Authentication failed',
        error: e,
        stack: stack,
      );
    } catch (e, stack) {
      UiErrorService.logAndShow(
        context: context,
        source: ErrorSource.auth,
        screen: 'AuthScreen',
        stage: ErrorStage.authentication,
        severity: ErrorSeverity.error,
        userMessage: 'Email sign-in failed',
        error: e,
        stack: stack,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Icon(Icons.auto_awesome, size: 64, color: AppColors.accent),

              const SizedBox(height: 16),

              const Text(
                'QA Genie Studio',

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: _emailCtrl,

                keyboardType: TextInputType.emailAddress,

                autocorrect: false,

                enableSuggestions: false,

                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  labelText: 'Email',

                  labelStyle: const TextStyle(color: AppColors.textSecondary),

                  filled: true,

                  fillColor: AppColors.card,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),

                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),

                    borderSide: const BorderSide(color: AppColors.border),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),

                    borderSide: const BorderSide(
                      color: AppColors.accent,
                      width: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _passCtrl,

                obscureText: true,

                autocorrect: false,

                enableSuggestions: false,

                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  labelText: 'Password',

                  labelStyle: const TextStyle(color: AppColors.textSecondary),

                  filled: true,

                  fillColor: AppColors.card,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),

                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),

                    borderSide: const BorderSide(color: AppColors.border),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),

                    borderSide: const BorderSide(
                      color: AppColors.accent,
                      width: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,

                child: ElevatedButton(
                  onPressed: _loading ? null : _signInWithEmail,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,

                    disabledBackgroundColor: AppColors.accent.withOpacity(0.5),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Sign In',

                          style: TextStyle(
                            fontWeight: FontWeight.bold,

                            color: Colors.black,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _loading ? null : _signInWithGoogle,

                icon: const Icon(Icons.login, color: Colors.white),

                label: const Text(
                  'Sign in with Google',

                  style: TextStyle(color: Colors.white),
                ),

                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
