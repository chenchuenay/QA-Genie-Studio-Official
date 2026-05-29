import 'package:flutter/material.dart';
import 'package:qa_genie/app/router/app_router.dart';
import 'package:qa_genie/app/theme/app_theme.dart';

class QaGenieApp extends StatefulWidget {
  const QaGenieApp({super.key});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_QaGenieAppState>()?.restart();
  }

  @override
  State<QaGenieApp> createState() => _QaGenieAppState();
}

class _QaGenieAppState extends State<QaGenieApp> {
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
        theme: AppTheme.darkTheme,
        initialRoute: AppRouter.startupRoute,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
