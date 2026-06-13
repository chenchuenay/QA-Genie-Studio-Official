import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/data/dto/generation_dto.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/core/config/app_environment.dart';
import 'package:qa_genie/core/error/ui_error_service.dart';
import 'package:qa_genie/core/state/generation_state.dart';
import 'package:qa_genie/app/startup/app_dependencies.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/shared/ui/no_internet_screen.dart';
import 'package:qa_genie/shared/widgets/watch_ad_dialog.dart';
import 'package:qa_genie/features/beta/logic/beta_manager.dart';
import 'package:qa_genie/features/monetization/ads/ad_units.dart';
import 'package:qa_genie/engine/forensics/trace_id_generator.dart';
import 'package:qa_genie/domain/usecases/save_suite_use_case.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/features/monetization/ads/ad_service.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/domain/usecases/generate_test_cases_use_case.dart';
import 'package:qa_genie/core/forensics/forensics_provider.dart';
import 'package:qa_genie/features/suites/ui/screens/suite_preview_screen.dart';
import 'package:qa_genie/features/forensics/diagnostics_persistence_service.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/shared/widgets/animated_dots.dart';
import 'package:qa_genie/features/monetization/ui/upgrade_screen.dart';

import 'package:qa_genie/core/utils/device_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final constraintsKey = GlobalKey();
  static final moduleKey = GlobalKey();
  static final featureKey = GlobalKey();
  static final platformKey = GlobalKey();
  static final generateKey = GlobalKey();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController mCtrl = TextEditingController();
  final TextEditingController fCtrl = TextEditingController();
  final TextEditingController cCtrl = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final GenerateTestCasesUseCase _generateUseCase =
      AppDependencies.generateTestCasesUseCase;
  final SaveSuiteUseCase _saveSuiteUseCase = AppDependencies.saveSuiteUseCase;
  late StreamSubscription<User?> _authSubscription;

  String platform = 'Web';
  bool loading = false;
  bool _isPro = false;
  int _rewardedRemaining = 6;
  int _proRemaining = 15;
  DateTime? _resetTime;

  @override
  void initState() {
    super.initState();
    _authSubscription = AuthService.authStateChanges.listen((user) {
      if (user != null) _refreshStatus();
    });
    _refreshStatus();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    mCtrl.dispose();
    fCtrl.dispose();
    cCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final isPro = await UsageManager.isPro();
    final rewardedRemaining = await UsageManager.rewardedGensRemaining();
    final proRemaining = await UsageManager.proGensRemaining();
    final resetTime = await UsageManager.getResetTime();

    if (!mounted) return;
    setState(() {
      _isPro = isPro;
      _rewardedRemaining = rewardedRemaining;
      _proRemaining = proRemaining;
      _resetTime = resetTime;
    });
  }

  String _generationHint() {
    if (_isPro) {
      return 'Generates 16 test cases per batch ($_proRemaining/15 left)';
    } else {
      if (_rewardedRemaining > 0) {
        return 'Watch ads for $_rewardedRemaining more generations today (8 cases each)';
      }

      String resetText = '';
      if (_resetTime != null) {
        final now = DateTime.now();
        final diff = _resetTime!.difference(now);
        if (diff.isNegative) {
          _refreshStatus();
        } else {
          final h = diff.inHours;
          final m = diff.inMinutes % 60;
          resetText = ' • Resets in ${h}h ${m}m';
        }
      }

      final suffix = AppConfig.isProduction ? '' : ' or reset limits in Test mode.';
      return 'Daily limit reached. Upgrade to PRO$resetText$suffix';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050505), Color(0xFF0A0A0A), Color(0xFF0D0D0D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<bool>(
            valueListenable: AdService.isAdLoading,
            builder: (context, isAdLoading, _) {
              final fullLock = loading || isAdLoading;
              return AbsorbPointer(
                absorbing: fullLock,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: fullLock ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              const Text(
                                'SPECIFICATION',
                                style: TextStyle(
                                  color: Color(0xFF46DFFF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 6,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                key: HomeScreen.moduleKey,
                                child: _input(
                                  'Module Name *',
                                  'e.g. User Authentication',
                                  mCtrl,
                                  maxLength: 40,
                                  enabled: !fullLock,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                key: HomeScreen.featureKey,
                                child: _input(
                                  'Feature *',
                                  'e.g. Login with Google OAuth',
                                  fCtrl,
                                  maxLength: 70,
                                  enabled: !fullLock,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Padding(
                                padding: EdgeInsets.only(left: 22),
                                child: Text(
                                  'Platform *',
                                  style: TextStyle(
                                    color: Color(0xFFA7AFBF),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                key: HomeScreen.platformKey,
                                child: _platformSelector(fullLock),
                              ),
                              const SizedBox(height: 20),
                              const Padding(
                                padding: EdgeInsets.only(left: 22),
                                child: Text(
                                  'Constraints (optional)',
                                  style: TextStyle(
                                    color: Color(0xFFA7AFBF),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _constraints(fullLock),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  _generationHint(),
                                  style: AppText.hint,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Container(
                        key: HomeScreen.generateKey,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: AdService.isAdLoading,
                          builder: (context, isAdLoading, _) {
                            final lock = loading || isAdLoading;
                            return Opacity(
                              opacity: lock ? 0.5 : 1.0,
                              child: _generateBtn(lock),
                            );
                          }
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _input(
    String label,
    String hint,
    TextEditingController ctrl, {
    int? maxLength,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      maxLength: maxLength,
      enabled: enabled,
      maxLengthEnforcement: maxLength != null
          ? MaxLengthEnforcement.enforced
          : MaxLengthEnforcement.none,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFFA7AFBF),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF8A90A2),
        ),
        filled: true,
        fillColor: const Color(0xFF0D0F14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 20,
        ),
        counterStyle: AppText.hint,
      ),
    );
  }

  Widget _platformSelector(bool locked) {
    return Container(
      height: 68,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F14),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x14FFFFFF), width: 1),
      ),
      child: Row(
        children: ['Mobile', 'Web', 'API'].map((p) {
          final selected = platform == p;
          return Expanded(
            child: GestureDetector(
              onTap: locked ? null : () => setState(() => platform = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF46DFFF), Color(0xFF7CEBFF)],
                        )
                      : null,
                  color: selected ? null : const Color(0xFF12141A),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    p,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF07131A)
                          : const Color(0xFF8A90A2),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _constraints(bool locked) {
    return TextFormField(
      controller: cCtrl,
      maxLines: 3,
      enabled: !locked,
      maxLength: EnvironmentAuthority.maxConstraintsLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'e.g. Must support WCAG 2.1 AA...',
        hintStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF8A90A2),
        ),
        filled: true,
        fillColor: const Color(0xFF0D0F14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(20),
        counterStyle: AppText.hint,
      ),
    );
  }

  Widget _generateBtn(bool isDisabled) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _generate,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(
                    colors: [
                      const Color(0xFF46DFFF).withOpacity(0.5),
                      const Color(0xFF7CEBFF).withOpacity(0.5),
                    ],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF46DFFF), Color(0xFF7CEBFF)],
                  ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: loading
                ? const AnimatedDots(
                    label: '⚡ Generating',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Generate Batch →',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _generate() async {
    FocusManager.instance.primaryFocus?.unfocus(); // Kill keyboard instantly
    if (!formKey.currentState!.validate()) return;
    
    // Set loading true immediately to block UI leaks
    setState(() => loading = true);
    GenerationState.isGenerating.value = true;

    if (AppConfig.isProduction) {
      final hasInternet = await NetworkGuard.hasInternet();
      if (!hasInternet) {
        if (mounted) setState(() => loading = false);
        final shouldRetry = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => NoInternetScreen(onRetry: () => _generate()),
          ),
        );
        if (shouldRetry != true) return;
        return;
      }
    }

    final isPro = await UsageManager.isPro();
    final deviceId = await DeviceUtils.getUniqueId();
    String? adToken;
    
    if (!isPro) {
      final shouldWatch = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const WatchAdDialog(featureName: 'Generate Test Cases'),
      );
      
      if (shouldWatch != true) {
        if (mounted) {
          setState(() {
            loading = false;
            GenerationState.isGenerating.value = false;
          });
        }
        return;
      }

      adToken = await AdService.showRewardedAd(
        adUnitId: AdUnits.rewardedTcGeneration,
        context: context,
      );
      if (adToken == null) {
        if (mounted) {
          setState(() {
            loading = false;
            GenerationState.isGenerating.value = false;
          });
        }
        return;
      }
    }
    stopwatch.stop();

    try {
      final module = mCtrl.text.trim();
      final feature = fCtrl.text.trim();
      final notes = cCtrl.text.trim();
      final currentPro = await UsageManager.isPro();
      final hardLimit = currentPro ? 16 : 8;

      final session = await _generateUseCase.execute(
        dto: GenerationDto(
          module: module,
          feature: feature,
          platform: platform,
          mode: currentPro ? GenerationMode.pro : GenerationMode.core,
          count: hardLimit,
          constraints: notes,
          traceId: TraceIdGenerator.generate(),
          adToken: adToken,
          deviceId: deviceId,
        ),
      );

      final suiteId = await _saveSuiteUseCase.createSuite(
        module: module,
        feature: feature,
        platform: platform,
      );

      await _saveSuiteUseCase.saveSuite(
        suiteId: suiteId,
        cases: session.testCases,
      );

      // Capture Forensic Context
      final forensicsContext = {
        'app_tier': currentPro ? 'PRO' : 'CORE',
        'quota_snapshot': currentPro ? _proRemaining : _rewardedRemaining,
        'ad_load_latency_ms': stopwatch.elapsedMilliseconds,
        'constraints_hash': notes.hashCode,
        'app_version': '1.0.0', 
      };
      
      // Update forensics
      await ForensicsProvider.instance.saveSnapshot(
        session: session,
        auditReport: const PipelineAuditReport(traceId: ''),
        rawAiResponse: '',
        forensicsContext: forensicsContext,
      );

      await UsageManager.incrementGeneration(
        count: hardLimit,
        rewarded: !currentPro,
      );
      await BetaManager.touch();
      await AdService.maybeShowInterstitial();
      await _refreshStatus();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            session: session,
            moduleName: module,
            feature: feature,
            platform: platform,
            suiteId: suiteId,
          ),
        ),
      );
    } on QuotaExceededException catch (e) {
      if (mounted) {
        _showLimitReachedDialog(e.message);
      }
    } catch (e, stackTrace) {
      UiErrorService.handle(e, stackTrace: stackTrace, category: 'generation');
      if (!mounted) return;
      showBlurredDialog(
        context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Generation Failed', style: TextStyle(color: Colors.white)),
          content: Text('$e', style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _generate();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
        GenerationState.isGenerating.value = false;
      }
    }
  }

  void _showLimitReachedDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock, color: AppColors.accent),
            SizedBox(width: 12),
            Text('Limit Reached', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '$message\n\nYou have used all your generations for today. Limits reset every 24 hours.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later', style: TextStyle(color: AppColors.textHint)),
          ),
          ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UpgradeScreen()),
            );
          },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Upgrade to PRO'),
          ),
        ],
      ),
    );
  }
}
