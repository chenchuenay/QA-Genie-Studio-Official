import 'package:flutter/material.dart';
import 'package:qa_app/core/config/app_config.dart';
import 'package:qa_app/core/theme/constants.dart';
import 'package:qa_app/core/utils/dialog_utils.dart';
import 'package:qa_app/application/services/generation_service.dart';
import 'package:qa_app/domain/usecases/generate_test_cases_use_case.dart';
import 'package:qa_app/domain/usecases/save_test_suite_use_case.dart';
import 'package:qa_app/features/beta/logic/beta_manager.dart';
import 'package:qa_app/features/generation/ui/screens/preview_screen.dart';
import 'package:qa_app/features/monetization/logic/usage_manager.dart';
import 'package:qa_app/features/monetization/ads/ad_service.dart';
import 'package:qa_app/presentation/widgets/ad_dialog.dart';

class HomeScreen extends StatefulWidget {
  static final constraintsKey = GlobalKey();
  const HomeScreen({super.key});

  static final moduleKey = GlobalKey();
  static final featureKey = GlobalKey();
  static final platformKey = GlobalKey();
  static final generateKey = GlobalKey();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final mCtrl = TextEditingController(),
      fCtrl = TextEditingController(),
      cCtrl = TextEditingController();
  String platform = "Web";
  bool loading = false;
  final formKey = GlobalKey<FormState>();
  final gen = GenerateTestCasesUseCase(), save = SaveTestSuiteUseCase();
  bool _isPro = false;
  int _freeRemaining = 3;
  int _proRemaining = 20;

  late AnimationController _dotCtrl;
  late List<Animation<double>> _dotAnims;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _dotAnims = [
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _dotCtrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
        ),
      ),
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _dotCtrl,
          curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
        ),
      ),
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _dotCtrl,
          curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
        ),
      ),
    ];
    _dotCtrl.repeat();
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

  Future<void> _refreshStatus() async {
    final pro = await UsageManager.isPro();
    final free = await UsageManager.freeGensRemaining();
    final proRem = await UsageManager.proGensRemaining();
    if (mounted)
      setState(() {
        _isPro = pro;
        _freeRemaining = free;
        _proRemaining = proRem;
      });
  }

  @override
  Widget build(BuildContext context) {
    String genHint;
    if (_isPro) {
      genHint =
          "Generates up to 20 test cases per batch (${_proRemaining}/20 left)";
    } else if (_freeRemaining > 0) {
      genHint =
          "Generates up to 10 test cases per batch (${_freeRemaining} free left)";
    } else {
      genHint = "Watch an ad to generate more";
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080808), Color(0xFF16161A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // RED BANNER – proves the new file is active
              Expanded(
                child: AbsorbPointer(
                  absorbing: loading,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SPECIFICATION",
                            style: TextStyle(
                              color: AppColors.accentLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            key: HomeScreen.moduleKey,
                            child: _input(
                              "Module Name *",
                              "e.g. User Authentication",
                              mCtrl,
                              (v) => v!.trim().isEmpty ? "Required" : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            key: HomeScreen.featureKey,
                            child: _input(
                              "Feature *",
                              "e.g. Login with Google OAuth",
                              fCtrl,
                              (v) => v!.trim().isEmpty ? "Required" : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const Text(
                            "Platform",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            key: HomeScreen.platformKey,
                            child: _platformSelector(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _constraints(),
                          const SizedBox(height: AppSpacing.md),
                          Center(child: Text(genHint, style: AppText.hint)),
                          const SizedBox(height: AppSpacing.md),
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
                  child: _generateBtn(),
                ),
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
    TextEditingController ctrl,
    String? Function(String?)? validator,
  ) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintText: hint,
        hintStyle: AppText.hint,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _platformSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: ["Mobile", "Web", "API"].map((p) {
          final sel = platform == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => platform = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: sel
                      ? const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: sel ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    p,
                    style: TextStyle(
                      color: sel ? Colors.black : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
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
      maxLength: AppConfig.maxConstraintsLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "e.g. Must support WCAG 2.1 AA, test on Chrome & Safari...",
        hintStyle: AppText.hint,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
        counterStyle: AppText.hint,
      ),
    );
  }

  Widget _generateBtn() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : _generate,
        style: ElevatedButton.styleFrom(
          backgroundColor: loading ? AppColors.card : AppColors.accent,
          foregroundColor: loading ? AppColors.textHint : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? _smoothDots()
            : const Text(
                "Generate Batch →",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _smoothDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Generating",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        for (int i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _dotAnims[i],
            builder: (_, child) => Opacity(
              opacity: _dotAnims[i].value,
              child: Text(
                ".",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _generate() async {
    if (!formKey.currentState!.validate()) return;
    final pro = await UsageManager.isPro();
    bool can = await UsageManager.canGenerate();
    if (!can && !pro) {
      final count = await UsageManager.getGenerationCount();
      if (count >= 3 && count < 10) {
        final watched = await showDialog<bool>(
          context: context,
          builder: (_) => const AdDialog(),
        );
        if (watched != true) return;
        can = await UsageManager.canGenerate(afterRewardedAd: true);
        if (!can) {
          if (mounted)
            showBlurredDialog(
              context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text(
                  "Limit Reached",
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  "Today's generation limit reached. Upgrade to Pro.",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          return;
        }
      } else {
        if (mounted)
          showBlurredDialog(
            context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                "Limit Reached",
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                "Today's generation limit reached. Upgrade to Pro.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        return;
      }
    }
    if (!can) return;
    setState(() => loading = true);
    try {
      final m = mCtrl.text.trim(),
          f = fCtrl.text.trim(),
          p = platform,
          n = cCtrl.text.trim();
      final result = await gen.execute(
        module: m,
        feature: f,
        platform: p,
        notes: n,
      );
      final cases = result.cases;
      final suiteId = await save.execute(
        module: m,
        feature: f,
        platform: p,
        cases: cases,
      );
      await UsageManager.incrementGeneration();
      await BetaManager.touch();
      await AdService().showInterstitialIfAppropriate();
      await _refreshStatus();
      final generationWarning = result.warning;
      if (mounted && generationWarning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(generationWarning),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      if (mounted)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PreviewScreen(
              testCases: cases,
              moduleName: m,
              feature: f,
              platform: p,
              suiteId: suiteId,
            ),
          ),
        );
    } catch (e) {
      if (mounted)
        showBlurredDialog(
          context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              "Generation Failed",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "$e",
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _generate();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
