import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qa_app/app/theme/constants.dart';
import 'package:qa_app/app/config/app_config.dart';

class LoginScreen extends StatefulWidget {
  final bool firebaseReady;
  const LoginScreen({super.key, required this.firebaseReady});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  // ---- Email Link Sign-In ----
  Future<void> _sendSignInLink() async {
    if (!widget.firebaseReady) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = _emailController.text.trim();
      final actionCodeSettings = ActionCodeSettings(
        url:
            'https://qagenieai.page.link/login', // update with your dynamic link
        handleCodeInApp: true,
        iOSBundleId: 'com.enaykumar.qagenie', // your bundle ID
        androidPackageName: 'com.enaykumar.qagenie', // your package name
        androidInstallApp: true,
        androidMinimumVersion: '1',
      );
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Sign‑in link sent! Check your email (including spam).",
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? "Sign‑in link failed");
    } catch (e) {
      setState(() => _error = "Could not send link: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---- Google Sign-In ----
  Future<void> _signInWithGoogle() async {
    if (!widget.firebaseReady) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final provider = GoogleAuthProvider();
      final userCredential = await FirebaseAuth.instance.signInWithProvider(
        provider,
      );
      if (userCredential.user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? "Google sign‑in failed");
    } catch (e) {
      setState(() => _error = "Google sign‑in error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---- Handle Email Link sign-in if the app was opened via link ----
  @override
  void initState() {
    super.initState();
    if (!widget.firebaseReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return;
    }
    // Check if the app was opened from an email link
    _trySignInWithEmailLink();
  }

  Future<void> _trySignInWithEmailLink() async {
    final auth = FirebaseAuth.instance;
    // Get the link from the initial uri if any
    final uri = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (uri.isNotEmpty) {
      try {
        final email = _emailController.text.trim();
        if (email.isEmpty) {
          // Prompt user to re-enter email
          return;
        }
        final cred = EmailAuthProvider.credentialWithLink(
          email: email,
          emailLink: uri,
        );
        await auth.signInWithCredential(cred);
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } catch (_) {
        // Invalid link or expired; handle silently
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // In test mode, skip login entirely
    if (!AppConfig.isProduction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "QA Genie",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Sign in to continue",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email address',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      hintText: 'you@example.com',
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendSignInLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Send Sign‑In Link",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("or", style: TextStyle(color: AppColors.textHint)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: const Text("Continue with Google"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
