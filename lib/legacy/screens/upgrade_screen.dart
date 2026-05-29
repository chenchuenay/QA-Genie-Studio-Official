import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.surface, title: const Text("Unlock Pro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Icon(Icons.auto_awesome, size: 48, color: AppColors.warning),
          const SizedBox(height: 12),
          const Text("Supercharge your QA workflow with unlimited test generation and exports.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.4)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _tableHeader("FREE"), _tableHeader("PRO"),
          ]),
          const SizedBox(height: 20),
          _featureRow("Test cases per batch", "10", "20"),
          _featureRow("Requests per day", "3 free + 7 via ads", "20"),
          _featureRow("Exports", "1st free, then via ads", "Unlimited"),
          _featureRow("Ads", "Limited", "None"),
          _featureRow("Test summary reports", "Limited", "Unlimited"),
          const SizedBox(height: 28),
          const Text("\$4.99 / month", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
            onPressed: () async { await UsageManager.setPro(true); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mock: Pro activated!"), backgroundColor: AppColors.success)); Navigator.pop(context); }},
            icon: const Icon(Icons.star, color: Colors.black),
            label: const Text("Upgrade to Pro", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, elevation: 8, shadowColor: AppColors.accent.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          )),
          const SizedBox(height: 12),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Maybe later", style: TextStyle(color: AppColors.textHint, fontSize: 14))),
          const SizedBox(height: 4),
          const Text("Cancel anytime. Billed monthly. No hidden fees.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textHint, fontSize: 11)),
        ]),
      ),
    );
  }
  Widget _tableHeader(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)), child: Text(text, style: TextStyle(color: text == "PRO" ? AppColors.accent : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)));
  Widget _featureRow(String label, String free, String pro) => Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: Row(children: [Expanded(flex:3, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))), Expanded(flex:2, child: Text(free, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textHint, fontSize: 14))), Expanded(flex:2, child: Text(pro, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 14)))]));
}
