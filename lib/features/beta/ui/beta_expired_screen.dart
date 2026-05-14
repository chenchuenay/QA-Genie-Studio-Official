import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/constants.dart';

class BetaExpiredScreen extends StatelessWidget {
  final bool isUpdateRequired;
  const BetaExpiredScreen({super.key, this.isUpdateRequired = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUpdateRequired ? Icons.system_update : Icons.timer_off,
                size: 64,
                color: AppColors.accent,
              ),
              const SizedBox(height: 24),
              Text(
                isUpdateRequired ? 'Update Required' : 'Beta Expired',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                isUpdateRequired
                    ? 'A newer version of QA Genie is available.\nPlease update to continue.'
                    : 'The beta period has ended.\nThank you for testing!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
