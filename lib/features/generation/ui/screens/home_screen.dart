import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/data/dto/generation_dto.dart';
import 'package:qa_genie/core/utils/device_utils.dart';
import 'package:qa_genie/core/config/app_environment.dart';
import 'package:qa_genie/core/error/exceptions.dart';
import 'package:qa_genie/core/security/content_filter.dart';
import 'package:qa_genie/core/ui/network_ui_helper.dart';
import 'package:qa_genie/core/error/ui_error_service.dart';
import 'package:qa_genie/core/state/generation_state.dart';
import 'package:qa_genie/app/startup/app_dependencies.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/shared/widgets/animated_dots.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/shared/widgets/watch_ad_dialog.dart';
import 'package:qa_genie/engine/forensics/trace_id_generator.dart';
import 'package:qa_genie/domain/usecases/save_suite_use_case.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/core/cloud/cloud_sync_service.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/features/monetization/ads/ad_manager.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/domain/usecases/generate_test_cases_use_case.dart';
import 'package:qa_genie/features/suites/ui/screens/suite_preview_screen.dart';
import 'package:qa_genie/features/account/ui/account_screen.dart';
import 'package:qa_genie/shared/dialogs/generation_progress_dialog.dart';

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

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
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
  int _rewardedRemaining = 0;
  int _proRemaining = AppConfig.proFreeBatchesPerDay;
  DateTime? _resetTime;
  int _adAttempts = 0;

  @override
  void initState() {
    super.initState();
    _authSubscription = AuthService.authStateChanges.listen((member) {
      if (member != null) {
        UsageManager.invalidateCache();
        _refreshStatus();
      }
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
    try {
      final results = await Future.wait([
        UsageManager.isPro(),
        UsageManager.rewardedGensRemaining(),
        UsageManager.proGensRemaining(),
        UsageManager.getResetTime(),
      ]);
      if (!mounted) return;
      setState(() {
        _isPro = (results[0] as bool?) ?? false;
        _rewardedRemaining = (results[1] as int?) ?? 0;
        _proRemaining = (results[2] as int?) ?? 0;
        _resetTime = results[3] as DateTime?;
      });
    } catch (e) {
      debugPrint('⚠️ _refreshStatus failed: $e');
    }
  }

  String _generationHint() {
    if (_isPro) {
      return 'Generates ${AppConfig.proCasesPerBatch} test cases per batch ($_proRemaining/${AppConfig.proFreeBatchesPerDay} left)';
    } else {
      if (_rewardedRemaining > 0) {
        final batchWord = _rewardedRemaining == 1 ? 'batch' : 'batches';
        return 'Tap Generate — watch an ad to unlock $_rewardedRemaining $batchWord remaining (${AppConfig.coreCasesPerBatch} cases each)';
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
          resetText = ' • Resets in${h > 0 ? ' ${h}h ${m}m' : ' ${m}m'}';
        }
      }
      return 'Daily limit reached${resetText.isNotEmpty ? resetText : ''}.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullLock = loading;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050505), Color(0xFF0A0A0A), Color(0xFF0D0D0D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AbsorbPointer(
          absorbing: fullLock,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshStatus,
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    child: SingleChildScrollView(
                    physics: fullLock
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'SPECIFICATION',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            key: HomeScreen.moduleKey,
                            child: _input(
                              'Module Name *',
                              'e.g. Member Authentication',
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
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
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
                          Container(
                            key: HomeScreen.constraintsKey,
                            child: _constraints(fullLock),
                          ),
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
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Container(
                    key: HomeScreen.generateKey,
                    child: AnimatedOpacity(
                      opacity: fullLock ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: _generateBtn(fullLock),
                    ),
                  ),
                ),
              ],
            ),
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
                      ? LinearGradient(
                          colors: [AppColors.accent, AppColors.accentLight],
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
      maxLines: 2,
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
                      AppColors.accent.withOpacity(0.5),
                      AppColors.accentLight.withOpacity(0.5),
                    ],
                  )
                : LinearGradient(
                    colors: [AppColors.accent, AppColors.accentLight],
                  ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: loading
                ? AnimatedDots(
                    label: '⚡ Generating',
                    style: const TextStyle(
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
    if (loading) return;
    debugPrint('🚀 _generate: Initializing');
    FocusManager.instance.primaryFocus?.unfocus();
    if (!formKey.currentState!.validate()) {
      debugPrint('❌ _generate: Validation failed');
      return;
    }

    setState(() => loading = true);
    GenerationState.isGenerating.value = true;

    final preChecks = await Future.wait([
      NetworkUiHelper.ensureProductionOnline(context),
      UsageManager.isPro(),
      DeviceUtils.getUniqueId(),
    ]);
    if (!(preChecks[0] as bool)) {
      if (mounted) {
        setState(() {
          loading = false;
          GenerationState.isGenerating.value = false;
        });
      }
      return;
    }

    final isPro = preChecks[1] as bool;
    final deviceId = preChecks[2] as String;
    String? rewardNonce;

    if (!isPro) {
      final remaining = await UsageManager.rewardedGensRemaining();
      if (remaining <= 0) {
        if (mounted) {
          setState(() {
            loading = false;
            GenerationState.isGenerating.value = false;
          });
          _showLimitReachedDialog(
            QuotaExceededException(
              'You have used all your generations for today.',
              resetTimeMillis: _resetTime?.difference(DateTime.now()).inMilliseconds,
            ),
          );
        }
        return;
      }

      debugPrint('🚀 _generate: Requesting ad nonce');
      try {
        rewardNonce = await FunctionsService.requestAdNonce();
      } catch (e) {
        debugPrint('❌ _generate: requestAdNonce failed: $e');
        if (mounted) {
          showBlurredDialog(
            context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Error', style: TextStyle(color: Colors.white)),
              content: const Text(
                'Failed to secure generation token. Please check your connection and try again.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK', style: TextStyle(color: AppColors.accent)),
                ),
              ],
            ),
          );
        }
        return;
      }

      debugPrint('🚀 _generate: Showing ad dialog');
      final shouldWatch = await showBlurredDialog<bool>(
        context,
        builder: (ctx) =>
            const WatchAdDialog(featureName: 'Generate Test Cases'),
      );
      if (shouldWatch != true) {
        debugPrint('⚠️ _generate: Ad dialog cancelled');
        if (mounted)
          setState(() {
            loading = false;
            GenerationState.isGenerating.value = false;
          });
        return;
      }

      debugPrint('🚀 _generate: Showing rewarded ad');
      final adResult = await AdManager().showRewardedAd();
      if (adResult == null) {
        debugPrint('❌ _generate: Show ad failed');
        if (mounted)
          setState(() {
            loading = false;
            GenerationState.isGenerating.value = false;
          });
        if (_adAttempts < 2) {
          _adAttempts++;
          AdManager().showStatusDialog(context, onRetry: () => _generate());
        } else {
          _adAttempts = 0;
          if (mounted) {
            showBlurredDialog(
              context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('Ad Unavailable', style: TextStyle(color: Colors.white)),
                content: const Text(
                  'Couldn\'t load an ad. Please check for ad blockers, VPNs, or network issues and try again.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK', style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
            );
          }
        }
        return;
      }
    }
    _adAttempts = 0;

    // Silence cloud pull for members before generation
    if (!AuthService.isGuest) {
      await CloudSyncService.pullRemoteSuites();
    }

    try {
      final module = mCtrl.text.trim();
      final feature = fCtrl.text.trim();
      final notes = cCtrl.text.trim();

      final moduleCheck = ContentFilter.check(module);
      final featureCheck = ContentFilter.check(feature);
      final notesCheck = notes.isNotEmpty ? ContentFilter.check(notes) : null;
      if (!moduleCheck.isClean || !featureCheck.isClean || (notesCheck?.isClean == false)) {
        debugPrint(
          '⚠️ _generate: Content filter blocked - module:${!moduleCheck.isClean} '
          'feature:${!featureCheck.isClean} notes:${notesCheck?.isClean == false}',
        );
        if (mounted) {
          showBlurredDialog(
            context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Input Guidelines', style: TextStyle(color: Colors.white)),
              content: const Text(
                'Please revise your input. Some content doesn\'t meet the guidelines.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(color: AppColors.accent)),
                ),
              ],
            ),
          );
        }
        return;
      }

      final currentPro = isPro;
      final hardLimit = currentPro
          ? AppConfig.proCasesPerBatch
          : AppConfig.coreCasesPerBatch;

      // Show generation progress dialog
      final stageController = StreamController<String>();
      unawaited(showBlurredDialog(
        context,
        barrierDismissible: false,
        builder: (ctx) => GenerationProgressDialog(
          stageStream: stageController.stream,
          onCancel: () {},
        ),
      ));

      debugPrint('🚀 _generate: Calling generateUseCase (AI)');
      GenerationSession session;
      int? suiteId;
      bool dialogPopped = false;
      try {
        session = await _generateUseCase.execute(
          dto: GenerationDto(
            module: module,
            feature: feature,
            platform: platform,
            mode: currentPro ? GenerationMode.pro : GenerationMode.core,
            count: hardLimit,
            constraints: notes,
            traceId: TraceIdGenerator.generate(),
            adToken: rewardNonce,
            deviceId: deviceId,
          ),
          onStageChange: (stage) => stageController.add(stage),
        );

        debugPrint('🚀 _generate: AI succeeded, saving suite locally');
        suiteId = await _saveSuiteUseCase.createSuite(
          module: module,
          feature: feature,
          platform: platform,
        );
        await _saveSuiteUseCase.saveSuite(
          suiteId: suiteId,
          cases: session.testCases,
        );

        // Pop dialog BEFORE pushing SuitePreviewScreen.
        // Both are on the same root navigator — if we push first,
        // the finally block's pop() would pop SuitePreviewScreen instead.
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          dialogPopped = true;
          if (session.testCases.isNotEmpty) {
            debugPrint('🚀 _generate: Navigating to SuitePreviewScreen');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SuitePreviewScreen(
                  session: session,
                  moduleName: module,
                  feature: feature,
                  platform: platform,
                  suiteId: suiteId!,
                ),
              ),
            );
          } else {
            debugPrint('⚠️ _generate: No test cases returned');
          }
        }
      } finally {
        await stageController.close();
        // Only pop if the dialog wasn't already dismissed above
        if (mounted && !dialogPopped) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }

      if (session.testCases.isEmpty && mounted && context.mounted) {
        showBlurredDialog(
          context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'No Cases Generated',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Generation produced no cases. Try a different input.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        );
      }

      // Background cloud sync + cache refresh (non-blocking)
      if (!AuthService.isGuest) {
        unawaited(CloudSyncService.pushPendingSuites().then((_) {
          debugPrint('🚀 _generate: cloud push completed');
        }).catchError((e) {
          debugPrint('❌ _generate: cloud push failed: $e');
        }));
      }

      UsageManager.invalidateCache();
      if (!isPro && rewardNonce != null) {
        setState(() { _rewardedRemaining = (_rewardedRemaining - 1).clamp(0, 999); });
      }
      unawaited(_refreshStatus());
      AccountScreen.markForRefresh();
    } on QuotaExceededException catch (e) {
      debugPrint('❌ _generate: Quota exceeded: $e');
      if (mounted) _showLimitReachedDialog(e);
    } catch (e, stackTrace) {
      debugPrint('❌ _generate: Unexpected error: $e');
      debugPrint(stackTrace.toString());
      UiErrorService.handle(e, stackTrace: stackTrace, category: 'generation');
      if (!mounted) return;
      final isRetriable = e is QaGenieException ? e.isRetriable : true;
      showBlurredDialog(
        context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Generation Failed',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            EnvironmentAuthority.isDev
                ? '$e'
                : isRetriable
                    ? 'Something went wrong. Please try again.'
                    : 'Generation cannot proceed with the current input. Please review and try a different approach.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            if (isRetriable)
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
      debugPrint('🚀 _generate: Flow completed (finally)');
      if (mounted)
        setState(() {
          loading = false;
          GenerationState.isGenerating.value = false;
        });
    }
  }

  void _showLimitReachedDialog(QuotaExceededException e) {
    String message = e.message;
    if (e.resetTimeMillis != null) {
      final hours = (e.resetTimeMillis! / (1000 * 60 * 60)).floor();
      final minutes = ((e.resetTimeMillis! / (1000 * 60)) % 60).floor();
      message += '\n\nResets in ${hours}h ${minutes}m.';
    } else {
      message +=
          '\n\nYou have used all your generations for today. Limits reset every 24 hours.';
    }
    showBlurredDialog(
      context,
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
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Got it',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
