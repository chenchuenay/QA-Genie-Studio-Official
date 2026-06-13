import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/features/auth/ui/auth_dialog.dart';
import 'package:qa_genie/features/beta/logic/beta_manager.dart';
import 'package:qa_genie/features/beta/ui/beta_expired_screen.dart';
import 'package:qa_genie/shared/navigation/main_screen.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/core/database/database_service.dart';

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
    // 1. Beta Check (Priority)
    final expired = await BetaManager.isExpired();
    final updateRequired = await BetaManager.isUpdateRequired();
    if (expired || updateRequired) {
      if (!mounted) return;
      setState(() {
        _expired = expired;
        _updateRequired = updateRequired;
        _loading = false;
      });
      return;
    }

    // 2. Ensure User Identity for Database
    final user = AuthService.currentUser;
    final identity = user?.uid ?? 'guest_default';
    await DatabaseService.initDatabase(identity);

    // 3. Check First Launch
    final prefs = await SharedPreferences.getInstance();
    final firstLaunch = prefs.getBool('first_launch_completed') ?? false;

    if (!firstLaunch) {
      if (!mounted) return;
      showBlurredDialog(
        context,
        builder: (ctx) => const AuthDialog(showGuestButton: true),
      );
      await prefs.setBool('first_launch_completed', true);
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show dark background while initializing or showing AuthDialog
    if (_loading) {
      return const Scaffold(backgroundColor: Color(0xFF020409));
    }

    if (_expired || _updateRequired) {
      return BetaExpiredScreen(isUpdateRequired: _updateRequired);
    }

    // Go to MainScreen (Guidelines will trigger there automatically)
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
