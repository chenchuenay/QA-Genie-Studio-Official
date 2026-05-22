import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/constants.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/presentation/screens/upgrade_coming_soon_screen.dart';

class ProBenefitsScreen extends StatefulWidget {
  final VoidCallback? onRestart;
  const ProBenefitsScreen({super.key, this.onRestart});
  @override
  State<ProBenefitsScreen> createState() => _ProBenefitsScreenState();
}

class _ProBenefitsScreenState extends State<ProBenefitsScreen> {
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
    await UsageManager.setPro(v);
    setState(() => _isPro = v);
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _row(
                    "Test cases per request",
                    _isPro ? "up to 16" : "up to 8",
                  ),
                  _row(
                    "Generation requests per day",
                    _isPro ? "15" : "1 free + 5 via ads",
                  ),
                  _row(
                    "Exports",
                    _isPro ? "Unlimited" : "1st free, then via ads",
                  ),
                  _row("Ads", _isPro ? "None" : "yes"),
                  _row(
                    "Test summary reports",
                    _isPro ? "Unlimited" : "Limited",
                  ),
                  const SizedBox(height: 30),
                  if (!AppConfig.isProduction)
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
                      onChanged: AppConfig.isProduction ? null : _togglePro,
                      activeColor: AppColors.accent,
                    ),
                  if (!AppConfig.isProduction) ...[
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
