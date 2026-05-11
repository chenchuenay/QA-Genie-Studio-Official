import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_app/app/config/app_config.dart';
import 'package:qa_app/presentation/animations/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (_) {
    // .env file may be missing – that's fine in beta
  }
  if (!AppConfig.isProduction) {
    final prefs = await SharedPreferences.getInstance();
    AppConfig.testProMode = prefs.getBool('testProMode') ?? false;
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static void restartApp(BuildContext context) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.restart();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Key _appKey = UniqueKey();
  void restart() {
    setState(() {
      _appKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _appKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'QA Genie Studio',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF080808),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00F0FF),
            secondary: Color(0xFF00F0FF),
            surface: Color(0xFF111115),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
