import 'package:qa_genie/main.dart';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/constants.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:qa_genie/presentation/widgets/bug_report_button.dart';
import 'package:qa_genie/presentation/widgets/guidelines_dialog.dart';
import 'package:qa_genie/features/suites/ui/screens/suites_screen.dart';
import 'package:qa_genie/presentation/screens/pro_benefits_screen.dart';
import 'package:qa_genie/features/generation/ui/screens/home_screen.dart';

class MainScreen extends StatefulWidget {
  static final _suitesTabKey = GlobalKey();
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _suitesKey = GlobalKey<SuitesScreenState>();
  final _starKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGuidelinesAutomatically();
    });
  }

  Future<void> _showGuidelinesAutomatically() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('never_show_guidelines', false);
    await prefs.setBool('first_launch_guidelines_shown', false);
    if (mounted) {
      showBlurredDialog(
        context,
        builder: (_) => GuidelinesDialog(
          showNeverAsk: true,
          onStartWalkthrough: startWalkthrough,
          autoScroll: true,
        ),
      );
    }
  }

  void _switchToGenerate() => setState(() => _currentIndex = 0);

  void startWalkthrough() {
    setState(() => _currentIndex = 0);
    final ctx = context;
    final m = "Enter the module you're testing.\ne.g. 'User Login'";
    final f = "Be specific about the feature.\ne.g. 'Login with Google OAuth'";
    final p = "Pick your platform: Mobile, Web, or API.";
    final c =
        "Optional constraints like WCAG, SSO, browsers, etc. (max 100 characters).";
    final g = "Tap to create your first test suite!";
    final s = "Your suites appear here. If empty, tap Generate to create one.";
    final a = "Manage your Core/Pro account, reset limits, or upgrade.";
    final targets = <TargetFocus>[
      TargetFocus(
        identify: "Module",
        keyTarget: HomeScreen.moduleKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (ctx, controller) => _card(m),
          ),
        ],
      ),
      TargetFocus(
        identify: "Feature",
        keyTarget: HomeScreen.featureKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (ctx, controller) => _card(f),
          ),
        ],
      ),
      TargetFocus(
        identify: "Platform",
        keyTarget: HomeScreen.platformKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (ctx, controller) => _card(p),
          ),
        ],
      ),
      TargetFocus(
        identify: "Constraints",
        keyTarget: HomeScreen.constraintsKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (ctx, controller) => _card(c),
          ),
        ],
      ),
      TargetFocus(
        identify: "Generate",
        keyTarget: HomeScreen.generateKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (ctx, controller) => _card(g),
          ),
        ],
      ),
      TargetFocus(
        identify: "SuitesTab",
        keyTarget: MainScreen._suitesTabKey,
        alignSkip: Alignment.topCenter,
        shape: ShapeLightFocus.RRect,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (ctx, controller) => _card(s),
          ),
        ],
      ),
      TargetFocus(
        identify: "Account",
        keyTarget: _starKey,
        alignSkip: Alignment.bottomLeft,
        shape: ShapeLightFocus.RRect,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (ctx, controller) => _card(a),
          ),
        ],
      ),
    ];
    TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.background.withOpacity(0.85),
      textSkip: "SKIP",
      paddingFocus: 12,
      opacityShadow: 0.7,
      onFinish: () {},
    ).show(context: ctx);
  }

  Widget _card(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent, width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 16),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1018),
        elevation: 0,
        title: const Text(
          "QA Genie Studio",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.info_outline, color: Color(0xFFB6BDCC)),
              tooltip: 'Guidelines',
              onPressed: () => showBlurredDialog(
                context,
                builder: (_) => GuidelinesDialog(
                  showNeverAsk: false,
                  onStartWalkthrough: startWalkthrough,
                ),
              ),
            ),
          const BugReportButton(),
          IconButton(
            key: _starKey,
            icon: const Icon(Icons.stars, color: Color(0xFF46DFFF)),
            tooltip: 'Account',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProBenefitsScreen(
                  onRestart: () => MyApp.restartApp(context),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          SuitesScreen(key: _suitesKey, onGenerate: _switchToGenerate),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 1) _suitesKey.currentState?.refresh();
        },
        backgroundColor: const Color(0xFF0D1018),
        selectedItemColor: const Color(0xFF3DDCFF),
        unselectedItemColor: const Color(0xFF6D7485),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.bolt),
            label: 'Generate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder, key: MainScreen._suitesTabKey),
            label: 'Suites',
          ),
        ],
      ),
    );
  }
}
