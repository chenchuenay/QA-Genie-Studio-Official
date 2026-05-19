import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/core/error/ui_error_store.dart';
import 'package:qa_genie/core/error/ui_error_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/core/logging/telemetry_collector.dart';
import 'package:qa_genie/presentation/navigation/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _setupErrorHandlers();

  await TelemetryCollector().initializeSystemSnapshot();

  try {
    await dotenv.load(fileName: '.env');

    debugPrint('✅ QAGenie .env loaded successfully');
  } catch (e) {
    debugPrint('⚠️ QAGenie .env not found: $e');
  }

  if (!AppConfig.isProduction) {
    final prefs = await SharedPreferences.getInstance();

    AppConfig.testProMode = prefs.getBool('testProMode') ?? false;
  }

  runApp(const QAGenieApp());
}

void _setupErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);

    UiErrorService.logOnly(
      source: ErrorSource.framework,
      screen: 'GLOBAL',
      stage: ErrorStage.runtime,
      severity: ErrorSeverity.critical,
      userMessage: 'Flutter framework error',
      error: details.exception,
      stack: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    UiErrorService.logOnly(
      source: ErrorSource.platform,
      screen: 'GLOBAL',
      stage: ErrorStage.runtime,
      severity: ErrorSeverity.critical,
      userMessage: 'Uncaught platform error',
      error: error,
      stack: stack,
    );

    return true;
  };
}

class QAGenieApp extends StatefulWidget {
  const QAGenieApp({super.key});

  static void restartApp(BuildContext context) {
    final state = context.findAncestorStateOfType<_QAGenieAppState>();

    state?.restart();
  }

  @override
  State<QAGenieApp> createState() => _QAGenieAppState();
}

class _QAGenieAppState extends State<QAGenieApp> {
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

        title: 'QA Genie',

        theme: ThemeData(
          brightness: Brightness.dark,

          scaffoldBackgroundColor: const Color(0xFF020409),

          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,

          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF46DFFF),
            secondary: Color(0xFF46DFFF),
            surface: Color(0xFF12141A),
          ),

          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Color(0xFF46DFFF),

            unselectedItemColor: Color(0xFF8D93A3),

            showUnselectedLabels: true,

            backgroundColor: Color(0xFF07090D),

            elevation: 0,

            type: BottomNavigationBarType.fixed,
          ),
        ),

        home: const MainScreen(),

        scrollBehavior: const MaterialScrollBehavior().copyWith(
          overscroll: false,
        ),
      ),
    );
  }
}
