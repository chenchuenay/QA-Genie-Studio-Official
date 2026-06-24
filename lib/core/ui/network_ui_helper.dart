import 'package:flutter/material.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/shared/ui/no_internet_screen.dart';

class NetworkUiHelper {
  static Future<bool> ensureProductionOnline(BuildContext context) async {
    // Always check actual internet access first — don't trust isOnline alone.
    final reallyOnline = await NetworkGuard.hasInternet();
    if (reallyOnline) return true;

    if (!context.mounted) return false;
    final bool? result = await showBlurredDialog<bool>(
      context,
      barrierDismissible: false,
      builder: (_) => const NoInternetScreen(),
    );
    return result == true;
  }
}
