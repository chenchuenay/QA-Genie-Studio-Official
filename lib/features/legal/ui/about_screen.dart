import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = packageInfo.version);
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'chenchuenay@qagenies.com',
      queryParameters: {'subject': 'QA Genie Feedback'},
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWebsite() async {
    final uri = Uri.parse('https://qagenies.com');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('About', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            Image.asset('assets/logo.png', width: 72, height: 72),
            const SizedBox(height: 12),
            const Text(
              'QA Genie',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version $_appVersion',
              style: const TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
            const SizedBox(height: 2),
            const Text(
              'AI-Powered Test Flow Engine',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _launchWebsite,
              child: const Text(
                'qagenies.com',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.accent,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 28),
            _sectionCard(
              children: [
                _sectionHeader('About QA Genie'),
                const SizedBox(height: 10),
                const Text(
                  'QA Genie is a mobile-first QA companion that generates professional '
                  'test cases from natural-language prompts. Built for QA engineers, '
                  'developers, and test managers who need high-quality test documentation '
                  'in seconds — not hours.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              children: [
                _sectionHeader('Key Features'),
                const SizedBox(height: 10),
                _featureItem(
                  'AI Test Generation',
                  'Describe your feature and get a full test suite tailored to your project.',
                ),
                _featureItem(
                  'Multiple Export Formats',
                  'Excel (.xlsx), Jira/Xray XML, and PDF — ready to share or import.',
                ),
                _featureItem(
                  'Test Suites',
                  'Organise, edit, and revisit your generated test cases anytime.',
                ),
                _featureItem(
                  'Smart Fallback',
                  'Seamlessly switches to a local fallback engine when AI generation encounters issues.',
                ),
                _featureItem(
                  'Export Summaries',
                  'Share concise test-summary reports with your team.',
                ),
                _featureItem(
                  'Risk-Based Sorting',
                  'Sort test cases by risk level automatically — security, negative, and high-priority cases rise to the top.',
                ),
                _featureItem(
                  'Batch Selection',
                  'Long-press to select multiple cases for batch copy, move, or delete.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              children: [
                _sectionHeader('Clarifications'),
                const SizedBox(height: 10),
                _featureItem(
                  'Multi-Device Usage',
                  'Logging in with the same Google account on multiple devices simultaneously may lead to unsaved data loss.',
                ),
                _featureItem(
                  'Cloud Sync (Members)',
                  'Sign in with Google to sync your test suites across devices. Guest data stays on device and is never uploaded.',
                ),
                _featureItem(
                  'Local Storage (Guests)',
                  'Guest data stays on this device and is never uploaded. Members access cloud sync.',
                ),
                _featureItem(
                  'Check Cloud vs Sync',
                  'Members only. "Check Cloud" pulls suites from server (one-way). Sync icon pushes local changes & pulls remote (two-way). Guests use local storage only.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              children: [
                _sectionHeader('Built With'),
                const SizedBox(height: 10),
                const Text(
                  'Flutter • Firebase (Auth, Firestore, Cloud Functions, Analytics) • '
                  ' AI • Google AdMob • Google Sign-In • '
                  'sqflite • PDF • Excel • share_plus • url_launcher • '
                  'connectivity_plus • device_info_plus • package_info_plus',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              children: [
                _sectionHeader('Contact'),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _launchEmail,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'chenchuenay@qagenies.com',
                        style: TextStyle(fontSize: 14, color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              '© 2026 QA Genie • Enay Kumar • All rights reserved',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }

  Widget _featureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '$title — ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



