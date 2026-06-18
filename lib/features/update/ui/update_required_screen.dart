import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/theme/app_radius.dart';
import 'package:qa_genie/features/update/logic/update_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateRequiredScreen extends StatefulWidget {
  final UpdateCheckResult check;

  const UpdateRequiredScreen({super.key, required this.check});

  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen> {
  late UpdateCheckResult _check;
  String _currentVersion = '...';

  @override
  void initState() {
    super.initState();
    _check = widget.check;
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final package = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _currentVersion = '${package.version}+${package.buildNumber}');
    } catch (_) {}
  }

  Future<void> _update() async {
    try {
      final uri = Uri.parse(_check.updateUrl);
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _later() async {
    await UpdateManager.recordDismissal();
    if (!mounted) return;
    final updated = await UpdateManager.checkForUpdate();
    if (!mounted) return;
    setState(() => _check = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.08),
                  blurRadius: 28,
                  spreadRadius: -10,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.22),
                        AppColors.accent.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    _check.blocked ? Icons.warning_amber_rounded : Icons.system_update,
                    size: 42,
                    color: _check.blocked ? AppColors.warning : AppColors.accent,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _check.blocked ? 'Update Required' : 'Update Available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _check.blocked
                      ? 'This version is no longer supported.\nPlease update to continue using QA Genie.'
                      : 'A new version (${_check.latestVersion}) is available.\nUpdate for the latest features and improvements.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.7),
                    ),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Current', _currentVersion),
                      const SizedBox(height: 10),
                      _infoRow('Required', '${_check.blockBelowBuild}+'),
                      if (!_check.blocked && _check.dismissCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.textHint,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_check.dismissCount}/3 reminders remaining',
                                  style: const TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _update,
                    icon: const Icon(Icons.download_rounded, color: Colors.black),
                    label: const Text(
                      'Update Now',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                ),
                if (!_check.blocked) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: _later,
                      child: const Text(
                        'Later',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Data stays local on this device and is not synced to the cloud.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
