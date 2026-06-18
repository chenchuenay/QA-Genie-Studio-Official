import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/theme/app_radius.dart';
import 'package:qa_genie/core/network/network_guard.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _checking = false;
  Timer? _autoRetryTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRetry();
  }

  @override
  void dispose() {
    _autoRetryTimer?.cancel();
    super.dispose();
  }

  void _startAutoRetry() {
    _autoRetryTimer?.cancel();
    _autoRetryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkInternet();
    });
  }

  Future<void> _checkInternet() async {
    if (_checking) return;
    if (!mounted) return;
    setState(() => _checking = true);

    final connected = await NetworkGuard.hasInternet();

    if (!mounted) return;

    if (connected) {
      _autoRetryTimer?.cancel();
      Navigator.pop(context, true);
    } else {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _checking ? Icons.wifi_find : Icons.cloud_off_rounded,
          size: 64,
          color: AppColors.accent,
        ),
        const SizedBox(height: 20),
        Text(
          _checking ? 'CHECKING CONNECTION…' : 'CONNECT TO INTERNET',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Generation and export require an internet connection.\nYour local suites, edits and reports remain available offline.',
            style: AppText.body,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        _statusCard(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _checking ? null : _checkInternet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: _checking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Retry Connection',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        if (_checking)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Auto-retrying every 10s…',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _autoRetryTimer?.cancel();
            Navigator.pop(context, false);
          },
          child: const Text(
            'Continue Offline',
            style: TextStyle(color: AppColors.textHint),
          ),
        ),
      ],
    );

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      content: SingleChildScrollView(child: content),
    );
  }

  Widget _statusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusRow('Browse Suites', true),
          _statusRow('Edit Test Cases', true),
          _statusRow('Update Execution Status', true),
          _statusRow('Save Local Changes', true),
          const SizedBox(height: 10),
          const Text(
            'Internet Required:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          _statusRow('Generate Test Cases', false),
          _statusRow('Export Files', false),
          _statusRow('Summary Export', false),
        ],
      ),
    );
  }

  Widget _statusRow(String text, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: enabled ? AppColors.success : AppColors.accent,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: enabled ? AppColors.textSecondary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
