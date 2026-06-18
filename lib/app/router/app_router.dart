import 'package:flutter/material.dart';
import 'package:qa_genie/features/splash/splash_screen.dart';

class AppRouter {
  static const String startupRoute = '/';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case startupRoute:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
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
