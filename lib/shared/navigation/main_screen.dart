import 'package:flutter/material.dart';
import 'package:qa_genie/app/app.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/core/state/generation_state.dart';
import 'package:qa_genie/shared/dialogs/guidelines_dialog.dart';
import 'package:qa_genie/shared/widgets/walkthrough_overlay.dart';
import 'package:qa_genie/features/monetization/ui/upgrade_screen.dart';
import 'package:qa_genie/features/suites/ui/screens/suites_screen.dart';
import 'package:qa_genie/features/monetization/ui/test_mode_screen.dart';
import 'package:qa_genie/features/account/ui/account_screen.dart';
import 'package:qa_genie/features/generation/ui/screens/home_screen.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';

class MainScreen extends StatefulWidget {
  static final _suitesTabKey = GlobalKey();
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  static bool shouldAutoStartTour = false;
  static final infoKey = GlobalKey();

  int _currentIndex = 0;
  bool _isPro = false;
  final _suitesKey = GlobalKey<SuitesScreenState>();
  final _starKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkProStatus();
    if (shouldAutoStartTour) {
      shouldAutoStartTour = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => startWalkthrough());
    }
  }

  Future<void> _checkProStatus() async {
    final pro = await UsageManager.isPro();
    if (!mounted) return;
    setState(() => _isPro = pro);
  }


  void _switchToGenerate() => setState(() => _currentIndex = 0);

  void startWalkthrough() {
    WalkthroughOverlay.show(
      context: context,
      steps: [
        WalkthroughStep(
          key: HomeScreen.moduleKey,
          icon: Icons.edit,
          title: 'Module Name',
          description: 'Start here — give your module a clear name, like \'User Authentication\'.',
        ),
        WalkthroughStep(
          key: HomeScreen.featureKey,
          icon: Icons.list_alt,
          title: 'Feature',
          description: 'Describe the specific feature, e.g. \'Login with Google OAuth.\'',
        ),
        WalkthroughStep(
          key: HomeScreen.platformKey,
          icon: Icons.phone_iphone,
          title: 'Platform',
          description: 'Pick a platform — Mobile, Web, or API. Each gives very different test cases.',
        ),
        WalkthroughStep(
          key: HomeScreen.constraintsKey,
          icon: Icons.lightbulb,
          title: 'Constraints',
          description: 'Add constraints (WCAG, SSO, timeouts) for realistic edge-case-rich tests.',
        ),
        WalkthroughStep(
          key: HomeScreen.generateKey,
          icon: Icons.bolt,
          title: 'Generate',
          description: 'Tap Generate to create your batch. Watch an ad to unlock more quota.',
        ),
        WalkthroughStep(
          key: MainScreenState.infoKey,
          icon: Icons.info_outline,
          title: 'Guidelines',
          description: 'Need a refresher? Tap here anytime for tips and the quick tour.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GenerationState.isGenerating,
      builder: (context, isGenerating, _) {
        return PopScope(
          canPop: !isGenerating,
          child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1018),
          elevation: 0,
          title: const Text(
            "QA Genie Studio",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (_currentIndex == 0)
              IconButton(
                key: MainScreenState.infoKey,
                icon: const Icon(
                  Icons.info_outline,
                  color: Color(0xFFB6BDCC),
                ),
                tooltip: 'Guidelines',
                onPressed: isGenerating
                    ? null
                    : () => showBlurredDialog(
                        context,
                        builder: (_) => GuidelinesDialog(
                          showNeverAsk: false,
                          autoScroll: true,
                          onStartWalkthrough: startWalkthrough,
                        ),
                      ),
              ),
            IconButton(
              key: _starKey,
              icon: _isPro
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, size: 16, color: Colors.black),
                    )
                  : const Icon(Icons.stars, color: AppColors.accent),
              tooltip: _isPro ? 'Pro' : 'Upgrade',
              onPressed: isGenerating
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UpgradeScreen(),
                      ),
                    ),
            ),
            IconButton(
              icon: const Icon(
                Icons.account_circle_outlined,
                color: AppColors.accent,
              ),
              tooltip: 'Account',
              onPressed: isGenerating
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountScreen(),
                      ),
                    ),
            ),
            if (!AppConfig.isProduction)
              IconButton(
                icon: const Icon(Icons.science, color: AppColors.accent),
                tooltip: 'Test Mode',
                onPressed: isGenerating
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TestModeScreen(
                            onRestart: () => QaGenieApp.restartApp(context),
                          ),
                        ),
                      ),
              ),
          ],
        ),
        body: Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: NetworkGuard.onlineStatus,
              builder: (context, online, _) {
                return AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  alignment: Alignment.topCenter,
                  child: online
                      ? const SizedBox.shrink()
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          color: AppColors.warning.withOpacity(0.15),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 14,
                                color: AppColors.warning,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'You are offline. Some features require internet.',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  const HomeScreen(),
                  SuitesScreen(key: _suitesKey, onGenerate: _switchToGenerate),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: AbsorbPointer(
          absorbing: isGenerating,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              if (isGenerating) return;
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
          ),
        ),
      );
    },
  );
  }
}
