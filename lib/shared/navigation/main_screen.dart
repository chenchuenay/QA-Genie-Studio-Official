import 'package:flutter/material.dart';
import 'package:qa_genie/app/app.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/core/state/generation_state.dart';
import 'package:qa_genie/shared/dialogs/guidelines_dialog.dart';
import 'package:qa_genie/shared/widgets/walkthrough_overlay.dart';
import 'package:qa_genie/features/monetization/ui/upgrade_screen.dart';
import 'package:qa_genie/features/suites/ui/screens/suites_screen.dart';
import 'package:qa_genie/features/account/ui/account_screen.dart';
import 'package:qa_genie/features/generation/ui/screens/home_screen.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/features/auth/services/session_monitor.dart';
import 'package:qa_genie/core/cloud/cloud_sync_service.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/features/update/logic/update_manager.dart';
import 'package:qa_genie/features/update/ui/update_required_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shouldAutoStartTour) {
        shouldAutoStartTour = false;
        startWalkthrough();
      }
      SessionMonitor.start(context);
    });
    _checkForUpdate();
  }

  @override
  void dispose() {
    SessionMonitor.stop();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    final check = await UpdateManager.checkForUpdate().timeout(
      const Duration(seconds: 2),
      onTimeout: () => UpdateManager.noUpdate(),
    );
    if (!mounted) return;
    if (check.updateRequired) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => UpdateRequiredScreen(check: check),
        ),
      );
    }
  }

  Future<void> _checkProStatus() async {
    final pro = await UsageManager.isPro();
    if (!mounted) return;
    setState(() => _isPro = pro);
  }


  void _switchToGenerate() => setState(() => _currentIndex = 0);

  Future<void> _triggerSync() async {
    if (!AuthService.isGuest) _suitesKey.currentState?.triggerSync();
  }

  void startWalkthrough() {
    WalkthroughOverlay.show(
      context: context,
      steps: [
        WalkthroughStep(
          key: HomeScreen.moduleKey,
          icon: Icons.edit,
          title: 'Module Name',
          description: 'Start here — give your module a clear name, like \'Member Authentication\'.',
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
          title: Text(
            _currentIndex == 0 ? 'QA Genie Studio' : 'Suites',
            style: const TextStyle(
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
            if (_currentIndex == 1 && !AuthService.isGuest)
              IconButton(
                icon: const Icon(Icons.cloud_sync, color: Color(0xFFB6BDCC)),
                tooltip: 'Sync Suites',
                onPressed: isGenerating ? null : _triggerSync,
              ),
            IconButton(
              key: _starKey,
              icon: _isPro
                  ? const Icon(Icons.star, color: AppColors.accent, size: 22)
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
            ...QaGenieApp.appBarActions,
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
