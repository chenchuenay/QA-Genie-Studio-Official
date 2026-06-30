import 'package:flutter/material.dart';
import 'package:qa_genie/app/router/app_router.dart';
import 'package:qa_genie/app/theme/app_theme.dart';

class QaGenieApp extends StatefulWidget {
  const QaGenieApp({super.key});

  static List<Widget> _appBarActions = const [];

  static void setAppBarActions(List<Widget> actions) {
    _appBarActions = actions;
  }

  static List<Widget> get appBarActions => _appBarActions;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_QaGenieAppState>()?.restart();
  }

  @override
  State<QaGenieApp> createState() => _QaGenieAppState();
}

class _QaGenieAppState extends State<QaGenieApp> {
  Key _appKey = UniqueKey();

  @override
  void initState() {
    super.initState();
  }

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
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaleFactor: mq.textScaleFactor.clamp(0.85, 1.2),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
