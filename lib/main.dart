import 'package:flutter/material.dart';
import 'package:qa_genie/app/app.dart';
import 'firebase/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/core/error/ui_error_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // ADDED for kReleaseMode

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: kReleaseMode ? ".env.prod" : ".env.dev");
  } catch (e) {
    debugPrint("Failed to load environment file: $e");
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    debugPrint("Firebase initialized successfully.");
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  if (!AppConfig.isProduction) {
    final prefs = await SharedPreferences.getInstance();
    AppConfig.testProMode = prefs.getBool('testProMode') ?? false;
  }

  runApp(const AnonymousAuthWrapper());
}

class AnonymousAuthWrapper extends StatefulWidget {
  const AnonymousAuthWrapper({super.key});

  @override
  State<AnonymousAuthWrapper> createState() => _AnonymousAuthWrapperState();
}

class _AnonymousAuthWrapperState extends State<AnonymousAuthWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _signInAnonymously();
  }

  Future<void> _signInAnonymously() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.isAnonymous) {
        debugPrint("Already signed in as: ${user.uid} (not anonymous)");
        _isLoading = false;
        return;
      }
      if (user == null) {
        final credential = await _auth.signInAnonymously();
        debugPrint(
          "Anonymous sign‑in successful. UID: ${credential.user?.uid}",
        );
        _isLoading = false;
      } else if (user.isAnonymous) {
        debugPrint("Already anonymous. UID: ${user.uid}");
        _isLoading = false;
      } else {
        debugPrint("Unexpected auth state. UID: ${user.uid}");
        _isLoading = false;
      }
    } catch (e, stackTrace) {
      debugPrint("Anonymous sign‑in failed: $e");
      UiErrorService.handle(e, stackTrace: stackTrace, category: 'auth');
      setState(() {
        _error = "Authentication failed. Please restart the app.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                      _signInAnonymously();
                    });
                  },
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const QaGenieApp();
  }
}
