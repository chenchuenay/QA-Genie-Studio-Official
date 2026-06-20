import 'package:flutter/material.dart';
import 'upgrade_coming_soon_screen.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/features/forensics/production_diagnostics_screen.dart';
import 'package:qa_genie/features/dev/fallback_analyzer_screen.dart';

class TestModeScreen extends StatefulWidget {
  final VoidCallback? onRestart;
  const TestModeScreen({super.key, this.onRestart});
  @override
  State<TestModeScreen> createState() => _TestModeScreenState();
}

class _TestModeScreenState extends State<TestModeScreen> {
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final pro = await UsageManager.isPro();
    if (mounted) setState(() => _isPro = pro);
  }

  Future<void> _togglePro(bool v) async {
    if (!AppConfig.allowDebugTools) return;
    await UsageManager.setPro(v);
    if (mounted) setState(() => _isPro = v);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            v
                ? "Switched to Pro – restarting…"
                : "Switched to Core – restarting…",
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onRestart?.call();
  }

  Future<void> _resetGenLimits() async {
    if (!AppConfig.allowDebugTools) return;
    await UsageManager.resetLimits();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Limits reset – restarting…"),
          backgroundColor: AppColors.success,
        ),
      );
    }
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onRestart?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Account (Test Mode)",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    _isPro ? Icons.diamond : Icons.person,
                    size: 60,
                    color: _isPro ? AppColors.accent : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isPro ? "You are a Pro" : "Core User",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _row(
                    "Test cases per request",
                    _isPro ? "up to ${AppConfig.proCasesPerBatch}" : "up to ${AppConfig.coreCasesPerBatch}",
                  ),
                  _row(
                    "Generation requests per day",
                    _isPro ? "15" : "Ad Sponsored",
                  ),
                  _row("Exports", _isPro ? "Unlimited" : "Ad Sponsored"),
                  _row("Ads", _isPro ? "No" : "Yes"),
                  _row(
                    "Test summary reports",
                    _isPro ? "Unlimited" : "Ad Sponsored",
                  ),
                  const SizedBox(height: 30),
                  if (AppConfig.allowDebugTools) ...[
                    SwitchListTile(
                      title: const Text(
                        "Test Mode: Pro",
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        "Restarts the app",
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                      value: _isPro,
                      onChanged: _togglePro,
                      activeColor: AppColors.accent,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _resetGenLimits,
                        icon: const Icon(
                          Icons.restart_alt,
                          color: AppColors.accent,
                        ),
                        label: const Text(
                          "Reset generation limits",
                          style: TextStyle(color: AppColors.accent),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: AppConfig.isProduction ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ProductionDiagnosticsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.analytics,
                          color: AppColors.accent,
                        ),
                        label: const Text(
                          "Production Diagnostics",
                          style: TextStyle(color: AppColors.accent),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: AppConfig.isProduction ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const FallbackAnalyzerScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.assessment,
                          color: AppColors.accent,
                        ),
                        label: const Text(
                          "Fallback Quality Analyzer",
                          style: TextStyle(color: AppColors.accent),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (!_isPro)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UpgradeComingSoonScreen(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Upgrade to Pro",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          if (_isPro) const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _row(String feature, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
