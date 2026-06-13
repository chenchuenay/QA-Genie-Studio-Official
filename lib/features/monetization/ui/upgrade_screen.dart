import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/theme/app_radius.dart';
import 'package:qa_genie/app/theme/app_spacing.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/features/monetization/ui/upgrade_coming_soon_screen.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  late Future<bool> _isProFuture;

  @override
  void initState() {
    super.initState();
    _isProFuture = UsageManager.isPro();
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
      body: FutureBuilder<bool>(
        future: _isProFuture,
        builder: (context, proSnapshot) {
          if (!proSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final isPro = proSnapshot.data!;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: isPro ? _buildProContent() : _buildUpgradeContent(),
            ),
          );
        },
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
          "You're enjoying the full QA Genie experience.",
        ),
        const SizedBox(height: AppSpacing.md),
        _benefitsGrid(isPro: true),
        const SizedBox(height: AppSpacing.lg),
        _compactCompareCard(),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Restore purchase (mock)"),
                  backgroundColor: AppColors.textHint,
                ),
              );
            },
            child: const Text(
              "Restore Purchase",
              style: TextStyle(color: AppColors.textHint, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _compactHero(
          "Generate More. Export More. Stay Focused.",
          "Unlock larger generations, unlimited exports, and an uninterrupted workflow.",
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
        description: isPro ? "Up to 16 cases per run" : "Generate bigger suites",
      ),
      _BenefitItem(
        icon: Icons.description,
        title: "Export Freely",
        description: isPro ? "Unlimited exports" : "Export without limits",
      ),
      _BenefitItem(
        icon: Icons.bar_chart,
        title: "Reports",
        description: isPro ? "Unlimited summary reports" : "Create unlimited reports",
      ),
      _BenefitItem(
        icon: Icons.block,
        title: "No Ads",
        description: isPro ? "Ad-free experience" : "Remove ads",
      ),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
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
            core: "8",
            pro: "16",
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
        const Center(
          child: Text(
            "\$7.99 / month",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            "Cancel anytime. No hidden fees.",
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              await FunctionsService.trackProInterest('proTab');
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UpgradeComingSoonScreen(),
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
        Center(
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Restore purchase (mock)"),
                  backgroundColor: AppColors.textHint,
                ),
              );
            },
            child: const Text(
              "Restore Purchase",
              style: TextStyle(color: AppColors.textHint, fontSize: 14),
            ),
          ),
        ),
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
          ),
          const SizedBox(height: 4),
          Text(
            item.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
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
