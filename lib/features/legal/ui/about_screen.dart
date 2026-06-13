import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/theme/app_spacing.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('About QA Genie', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'QA Genie',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'AI-Powered Test Flow Engine',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Version $_appVersion',
                style: const TextStyle(fontSize: 14, color: AppColors.textHint),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '© 2025 QA Genie',
                style: TextStyle(fontSize: 14, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
