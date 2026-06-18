import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/theme/app_radius.dart';
import 'package:qa_genie/app/theme/app_spacing.dart';
import 'package:qa_genie/features/legal/data/legal_documents.dart';
import 'package:qa_genie/features/legal/ui/document_view_screen.dart';

class TermsPrivacyPolicyScreen extends StatelessWidget {
  const TermsPrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Policies', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _policyItem(context, 'Privacy Policy', LegalDocuments.privacyPolicy, LegalDocuments.privacyPolicyUrl),
          _policyItem(context, 'Terms of Use', LegalDocuments.termsOfUse, LegalDocuments.termsOfServiceUrl),
          _policyItem(context, 'AI Disclaimer', LegalDocuments.aiDisclaimer, LegalDocuments.aiDisclaimerUrl),
          _policyItem(context, 'Ads & Monetization', LegalDocuments.adsPolicy, LegalDocuments.adsPolicyUrl),
        ],
      ),
    );
  }

  Widget _policyItem(BuildContext context, String title, String content, [String? url]) {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.accent),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentViewScreen(title: title, content: content, onlineUrl: url),
          ),
        ),
      ),
    );
  }
}
