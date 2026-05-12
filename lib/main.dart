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
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Color(0xFF46DFFF),
            unselectedItemColor: Color(0xFF8D93A3),
            showUnselectedLabels: true,
            backgroundColor: Color(0xFF07090D),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
          ),
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF020409),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF46DFFF),
            secondary: Color(0xFF46DFFF),
            surface: Color(0xFF12141A),
          ),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        home: const SplashScreen(),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
      ),
      ),
    );
  }
}
