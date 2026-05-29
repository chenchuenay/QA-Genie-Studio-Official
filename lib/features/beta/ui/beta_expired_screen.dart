import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qa_genie/features/beta/logic/beta_manager.dart';
// lib/features/beta/ui/beta_expired_screen.dart

class BetaExpiredScreen extends StatefulWidget {
  final bool isUpdateRequired;

  const BetaExpiredScreen({super.key, this.isUpdateRequired = false});

  @override
  State<BetaExpiredScreen> createState() => _BetaExpiredScreenState();
}

class _BetaExpiredScreenState extends State<BetaExpiredScreen> {
  String _build = '...';

  bool _tamperDetected = false;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    final package = await PackageInfo.fromPlatform();

    final tamper = await BetaManager.hasClockTamper();

    if (!mounted) return;

    setState(() {
      _build = '${package.version}+${package.buildNumber}';

      _tamperDetected = tamper;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isUpdateRequired ? 'Update Required' : 'Beta Expired';

    final description = widget.isUpdateRequired
        ? 'This QA Genie build is no longer supported.\nPlease update to continue generation and exports.'
        : 'The beta period has ended.\nExisting suites remain accessible in read-only mode.';

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
              borderRadius: BorderRadius.circular(24),
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
                    widget.isUpdateRequired
                        ? Icons.system_update
                        : Icons.timer_off,
                    size: 42,
                    color: AppColors.accent,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  description,
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.7),
                    ),
                  ),

                  child: Column(
                    children: [
                      _infoRow('Build', _build),

                      const SizedBox(height: 10),

                      _infoRow('Environment', 'Production Beta'),

                      if (_tamperDetected)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Clock inconsistency detected.',
                                  style: TextStyle(
                                    color: AppColors.warning,
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
                    onPressed: () {},

                    icon: const Icon(
                      Icons.download_rounded,
                      color: Colors.black,
                    ),

                    label: const Text(
                      'Update App',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Your data stays local on your device.',
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
