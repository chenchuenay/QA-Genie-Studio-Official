import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qa_genie/features/beta/logic/beta_manager.dart';
import 'package:qa_genie/features/beta/ui/beta_expired_screen.dart';
import 'package:qa_genie/shared/navigation/main_screen.dart'; // ✅ use MainScreen

class AppRouter {
  static const String startupRoute = '/';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case startupRoute:
        return MaterialPageRoute(
          builder: (_) => const _StartupGate(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const _UnknownRouteScreen(),
          settings: settings,
        );
    }
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _loading = true;
  bool _expired = false;
  bool _updateRequired = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('AUTH_START');

    // Anonymous Auth Gate
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        debugPrint('AUTH_SIGNING_IN_ANONYMOUSLY');
        await FirebaseAuth.instance.signInAnonymously();
      } catch (e, st) {
        debugPrint('AUTH_FAILED: $e');
        debugPrint('AUTH_STACK: $st');
      }
    }

    debugPrint('AUTH_UID=${FirebaseAuth.instance.currentUser?.uid}');
    debugPrint('AUTH_COMPLETE');

    final expired = await BetaManager.isExpired();
    final updateRequired = await BetaManager.isUpdateRequired();
    if (!mounted) return;
    setState(() {
      _expired = expired;
      _updateRequired = updateRequired;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF020409),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF46DFFF)),
        ),
      );
    }

    if (_expired || _updateRequired) {
      return BetaExpiredScreen(isUpdateRequired: _updateRequired);
    }

    // ✅ Go to MainScreen (tabs with AppBar and bottom navigation)
    return const MainScreen();
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF020409),
      body: Center(
        child: Text('Route not found', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}