import 'package:flutter/material.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/theme/app_radius.dart';
import 'package:qa_genie/app/theme/app_spacing.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _isPro = false;
  bool _isTapping = false;

  @override
  void initState() {
    super.initState();
    _isPro = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          "QA Genie Pro",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: _isPro ? _buildProContent() : _buildUpgradeContent(),
        ),
      ),
    );
  }

  Widget _buildProContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _compactHero(
          "PRO ACTIVE",
          "You're enjoying the full QA Genie experience (${AppConfig.proMonthlyPrice}/mo value).",
        ),
        const SizedBox(height: AppSpacing.md),
        _benefitsGrid(isPro: true),
        const SizedBox(height: AppSpacing.lg),
        _compactCompareCard(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildUpgradeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _compactHero(
          "Interested in Pro?",
          "Larger batches, unlimited exports, and an ad-free experience at ${AppConfig.proMonthlyPrice}/mo.",
        ),
        const SizedBox(height: AppSpacing.md),
        _benefitsGrid(isPro: false),
        const SizedBox(height: AppSpacing.lg),
        _compactCompareCard(),
        const SizedBox(height: AppSpacing.xl),
        _pricingAndCta(),
      ],
    );
  }

  Widget _compactHero(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _benefitsGrid({required bool isPro}) {
    final items = [
      _BenefitItem(
        icon: Icons.flash_on,
        title: "Larger Suites",
        description: isPro ? "Up to ${AppConfig.proCasesPerBatch} cases per run" : "Coming soon — bigger batches",
      ),
      _BenefitItem(
        icon: Icons.description,
        title: "Export Freely",
        description: isPro ? "Unlimited exports" : "Coming soon — no limits",
      ),
      _BenefitItem(
        icon: Icons.bar_chart,
        title: "Reports",
        description: isPro ? "Unlimited summary reports" : "Coming soon — unlimited",
      ),
      _BenefitItem(
        icon: Icons.block,
        title: "No Ads",
        description: isPro ? "Ad-free experience" : "Coming soon — ad-free",
      ),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: items.map((item) => _BenefitCard(item: item)).toList(),
    );
  }

  Widget _compactCompareCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _CompareRow(
            feature: "Cases / Run",
            core: "${AppConfig.coreCasesPerBatch}",
            pro: "${AppConfig.proCasesPerBatch}",
            isHeader: true,
          ),
          _CompareRow(
            feature: "Generations",
            core: "Limited",
            pro: "More",
          ),
          _CompareRow(
            feature: "Exports",
            core: "Limited",
            pro: "Unlimited",
          ),
          _CompareRow(
            feature: "Reports",
            core: "Limited",
            pro: "Unlimited",
          ),
          _CompareRow(feature: "Ads", core: "Yes", pro: "No"),
        ],
      ),
    );
  }

  Widget _pricingAndCta() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          'Just ${AppConfig.proMonthlyPrice}/mo',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isTapping ? null : () async {
              setState(() => _isTapping = true);
              await UsageManager.trackProInterest('upgrade_screen_cta');
              if (!context.mounted) return;
              setState(() => _isTapping = false);
              showBlurredDialog(
                context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.dialog),
                  ),
                  title: const Text(
                    'Thanks for your interest!',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  content: const Text(
                    'Our billing system is still cooking.\nWe\'ll notify you when it\'s ready.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              elevation: 8,
              shadowColor: AppColors.accent.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: const Text(
              "UNLOCK PRO",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Restore Purchase hidden for initial launch (Investor request)
      ],
    );
  }
}

class _BenefitItem {
  final IconData icon;
  final String title;
  final String description;
  _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _BenefitCard extends StatelessWidget {
  final _BenefitItem item;
  const _BenefitCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: AppColors.accent, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            item.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String feature;
  final String core;
  final String pro;
  final bool isHeader;
  const _CompareRow({
    required this.feature,
    required this.core,
    required this.pro,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: TextStyle(
                color: isHeader ? AppColors.accent : Colors.white,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              core,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isHeader ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              pro,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
