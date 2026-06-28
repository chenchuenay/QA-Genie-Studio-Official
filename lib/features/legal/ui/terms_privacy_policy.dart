import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/theme/app_radius.dart';
import 'package:qa_genie/app/theme/app_spacing.dart';
import 'package:qa_genie/features/legal/data/legal_documents.dart';
import 'package:url_launcher/url_launcher.dart';

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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Text(
              'The links below take you to external pages with full information about our policies.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _linkItem(context, 'Privacy Policy', LegalDocuments.privacyPolicyUrl),
          _linkItem(context, 'Terms of Service', LegalDocuments.termsOfServiceUrl),
          _linkItem(context, 'AI Disclaimer', LegalDocuments.aiDisclaimerUrl),
          _linkItem(context, 'Ads & Monetization', LegalDocuments.adsPolicyUrl),
          _linkItem(context, 'Account Deletion', LegalDocuments.deleteAccountUrl),
          _linkItem(context, 'Analytics Data', LegalDocuments.analyticsDataUrl),
        ],
      ),
    );
  }

  Widget _linkItem(BuildContext context, String title, String url) {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.open_in_new, color: AppColors.accent, size: 18),
        ),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ),
    );
  }
}
