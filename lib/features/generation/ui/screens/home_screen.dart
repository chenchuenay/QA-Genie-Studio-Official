import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/data/dto/generation_dto.dart';
import 'package:qa_genie/core/config/app_environment.dart';
import 'package:qa_genie/core/error/ui_error_service.dart';
import 'package:qa_genie/app/startup/app_dependencies.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/features/beta/logic/beta_manager.dart';
import 'package:qa_genie/engine/forensics/trace_id_generator.dart';
import 'package:qa_genie/domain/usecases/save_suite_use_case.dart';
import 'package:qa_genie/features/monetization/ads/ad_service.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/domain/usecases/generate_test_cases_use_case.dart';
import 'package:qa_genie/features/suites/ui/screens/suite_preview_screen.dart';

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

  late final AnimationController _dotCtrl;
  late final List<Animation<double>> _dotAnims;

  String platform = 'Web';
  bool loading = false;
  bool _isPro = false;
  int _freeRemaining = 1;
  int _rewardedRemaining = 5;
  int _proRemaining = 15;

  @override
  void initState() {
    super.initState();
    _initializeDots();
    _refreshStatus();
  }

  @override
  void dispose() {
    mCtrl.dispose();
    fCtrl.dispose();
    cCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  void _initializeDots() {
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _dotAnims = [
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _dotCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeInOut)),
      ),
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _dotCtrl, curve: const Interval(0.2, 0.6, curve: Curves.easeInOut)),
      ),
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _dotCtrl, curve: const Interval(0.4, 0.8, curve: Curves.easeInOut)),
      ),
    ];
    _dotCtrl.repeat();
  }

  Future<void> _refreshStatus() async {
    final isPro = await UsageManager.isPro();
    final freeRemaining = await UsageManager.freeGensRemaining();
    final rewardedRemaining = await UsageManager.rewardedGensRemaining();
    final proRemaining = await UsageManager.proGensRemaining();
    if (!mounted) return;
    setState(() {
      _isPro = isPro;
      _freeRemaining = freeRemaining;
      _rewardedRemaining = rewardedRemaining;
      _proRemaining = proRemaining;
    });
  }

  String _generationHint() {
    if (_isPro) return 'Generates up to 16 test cases per batch ($_proRemaining/15 left)';
    if (_freeRemaining > 0) return '1 free generation remaining today';
    if (_rewardedRemaining > 0) return 'Watch ads for $_rewardedRemaining more generations today';
    return 'Daily limit reached. Upgrade to PRO.';
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold here – the outer MainScreen provides the Scaffold.
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
          child: Column(
            children: [
              Expanded(
                child: AbsorbPointer(
                  absorbing: loading,
                  child: SingleChildScrollView(
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
                            decoration: const BoxDecoration(
                              boxShadow: [BoxShadow(color: Color(0x1A22D3EE), blurRadius: 22, spreadRadius: 0.5, offset: Offset(0, 6))],
                            ),
                            child: _input(
                              'Module Name *',
                              'e.g. User Authentication',
                              mCtrl,
                              maxLength: 40,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            key: HomeScreen.featureKey,
                            decoration: const BoxDecoration(
                              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, 8))],
                            ),
                            child: _input(
                              'Feature *',
                              'e.g. Login with Google OAuth',
                              fCtrl,
                              maxLength: 70,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Padding(
                            padding: EdgeInsets.only(left: 22),
                            child: Text('Platform *', style: TextStyle(color: Color(0xFFA7AFBF), fontSize: 15, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(height: 8),
                          Container(key: HomeScreen.platformKey, child: _platformSelector()),
                          const SizedBox(height: 20),
                          const Padding(
                            padding: EdgeInsets.only(left: 22),
                            child: Text('Constraints (optional)', style: TextStyle(color: Color(0xFFA7AFBF), fontSize: 15, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(height: 14),
                          _constraints(),
                          const SizedBox(height: 12),
                          Center(child: Text(_generationHint(), style: AppText.hint, textAlign: TextAlign.center)),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Container(key: HomeScreen.generateKey, child: _generateBtn()),
              ),
            ],
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      maxLength: maxLength,
      maxLengthEnforcement: maxLength != null ? MaxLengthEnforcement.enforced : MaxLengthEnforcement.none,
      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFA7AFBF), fontSize: 15, fontWeight: FontWeight.w500),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF8A90A2)),
        filled: true,
        fillColor: const Color(0xFF0D0F14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0x14FFFFFF), width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0x14FFFFFF), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0xFF46DFFF), width: 1.3)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        counterStyle: AppText.hint,
      ),
    );
  }

  Widget _platformSelector() {
    return Container(
      height: 68,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F14),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x14FFFFFF), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 18, spreadRadius: -6, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: ['Mobile', 'Web', 'API'].map((p) {
          final selected = platform == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => platform = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: selected ? const LinearGradient(colors: [Color(0xFF46DFFF), Color(0xFF7CEBFF)]) : null,
                  color: selected ? null : const Color(0xFF12141A),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    p,
                    style: TextStyle(
                      color: selected ? const Color(0xFF07131A) : const Color(0xFF8A90A2),
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

  Widget _constraints() {
    return TextFormField(
      controller: cCtrl,
      maxLines: 3,
      maxLength: EnvironmentAuthority.maxConstraintsLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'e.g. Must support WCAG 2.1 AA, test on Chrome & Safari...',
        hintStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF8A90A2)),
        filled: true,
        fillColor: const Color(0xFF0D0F14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0x14FFFFFF), width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0x14FFFFFF), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0xFF46DFFF), width: 1.3)),
        contentPadding: const EdgeInsets.all(20),
        counterStyle: AppText.hint,
      ),
    );
  }

  Widget _generateBtn() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: loading ? null : _generate,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: loading ? null : const LinearGradient(colors: [Color(0xFF46DFFF), Color(0xFF7CEBFF)]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: const Color(0xFF46DFFF).withOpacity(0.16), blurRadius: 22, spreadRadius: -10, offset: const Offset(0, 10))],
          ),
          child: Center(
            child: loading
                ? _smoothDots()
                : const Text('Generate Batch →', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: Colors.black)),
          ),
        ),
      ),
    );
  }

  Widget _smoothDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Generating', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        for (int i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _dotAnims[i],
            builder: (_, child) => Opacity(
              opacity: _dotAnims[i].value,
              child: Text('.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textHint)),
            ),
          ),
      ],
    );
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;

    bool canGenerate = await UsageManager.canGenerate();
    final isPro = await UsageManager.isPro();
    var usedRewardedAd = false;

    if (!canGenerate && !isPro) {
      final rewardedRemaining = await UsageManager.rewardedGensRemaining();
      if (rewardedRemaining > 0) {
        final watched = await AdService.showRewardedAd(
          adUnitId: 'ca-app-pub-.../generation_reward',
          onRewarded: () {},
          context: context,
        );
        if (!watched) return;
        usedRewardedAd = true;
        canGenerate = await UsageManager.canGenerate(afterRewardedAd: true);
      } else {
        if (mounted) {
          showBlurredDialog(
            context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Limit Reached', style: TextStyle(color: Colors.white)),
              content: const Text('Today\'s generation limit reached. Upgrade to PRO.', style: TextStyle(color: AppColors.textSecondary)),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
            ),
          );
        }
        return;
      }
    }

    if (!canGenerate) return;

    setState(() => loading = true);

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

      await UsageManager.incrementGeneration(rewarded: usedRewardedAd && !currentPro);
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () { Navigator.pop(ctx); _generate(); }, child: const Text('Retry')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}