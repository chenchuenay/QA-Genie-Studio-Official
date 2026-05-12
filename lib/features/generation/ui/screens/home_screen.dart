import 'package:flutter/services.dart';
import 'package:qa_app/presentation/widgets/press_effect.dart';
import 'package:flutter/material.dart';
import 'package:qa_app/app/config/app_config.dart';
import 'package:qa_app/app/theme/constants.dart';
import 'package:qa_app/core/utils/dialog_utils.dart';
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
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Micro-texture noise overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.012,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF46DFFF),
                      Color(0xFF050505),
                      Color(0xFF46DFFF),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF050505),
                  Color(0xFF0A0A0A),
                  Color(0xFF0D0D0D),
                ],
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
                                "SPECIFICATION",
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x1A22D3EE),
                                      blurRadius: 22,
                                      spreadRadius: 0.5,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: _input(
                                  "Module Name *",
                                  "e.g. User Authentication",
                                  mCtrl,
                                  maxLength: 40,
                                  validator: (v) =>
                                      v!.trim().isEmpty ? "Required" : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                key: HomeScreen.featureKey,
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 24,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: _input(
                                  "Feature *",
                                  "e.g. Login with Google OAuth",
                                  fCtrl,
                                  maxLength: 70,
                                  validator: (v) =>
                                      v!.trim().isEmpty ? "Required" : null,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Padding(
                                padding: EdgeInsets.only(left: 22),
                                child: Text(
                                  "Platform *",
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
                                child: _platformSelector(),
                              ),
                              const SizedBox(height: 20),
                              const Padding(
                                padding: EdgeInsets.only(left: 22),
                                child: Text(
                                  "Constraints (optional)",
                                  style: TextStyle(
                                    color: Color(0xFFA7AFBF),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _constraints(),
                              const SizedBox(height: 12),
                              Center(child: Text(genHint, style: AppText.hint)),
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
                      child: _generateBtn(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
      validator: validator,
      maxLength: maxLength,
      maxLengthEnforcement: maxLength != null
          ? MaxLengthEnforcement.enforced
          : MaxLengthEnforcement.none,
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
          borderSide: const BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFF46DFFF), width: 1.3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 20,
        ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 18,
            spreadRadius: -6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: ["Mobile", "Web", "API"].map((p) {
          final sel = platform == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => platform = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: sel
                      ? const LinearGradient(
                          colors: [Color(0xFF46DFFF), Color(0xFF7CEBFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: sel ? null : const Color(0xFF12141A),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    p,
                    style: TextStyle(
                      color: sel
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

  Widget _constraints() {
    return TextFormField(
      controller: cCtrl,
      maxLines: 3,
      maxLength: AppConfig.maxConstraintsLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "e.g. Must support WCAG 2.1 AA, test on Chrome & Safari...",
        hintStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF8A90A2),
        ),
        filled: true,
        fillColor: const Color(0xFF0D0F14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFF46DFFF), width: 1.3),
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: loading
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF46DFFF), Color(0xFF7CEBFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF46DFFF).withOpacity(0.16),
                blurRadius: 22,
                spreadRadius: -10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? _smoothDots()
                : const Text(
                    "Generate Batch →",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: Colors.black,
                    ),
                  ),
          ),
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
