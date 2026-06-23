import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/app/theme/app_theme.dart';

class GuidelinesDialog extends StatefulWidget {
  final bool showNeverAsk;
  final VoidCallback? onStartWalkthrough;
  final bool autoScroll;
  final bool showTourButton;

  const GuidelinesDialog({
    super.key,
    this.showNeverAsk = true,
    this.onStartWalkthrough,
    this.autoScroll = false,
    this.showTourButton = true,
  });

  @override State<GuidelinesDialog> createState() => _GuidelinesDialogState();
}

class _GuidelinesDialogState extends State<GuidelinesDialog> {
  bool _dontShowAgain = false;
  final ScrollController _scrollController = ScrollController();

  @override void initState() {
    super.initState();
    if (widget.autoScroll) {
      Future.delayed(const Duration(seconds: 2), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch_guidelines_shown', true);
    if (_dontShowAgain) {
      await prefs.setBool('never_show_guidelines', true);
    }
  }

  @override Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("How to get the best test cases",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _tip(Icons.edit, "1. Clear module name", "Name it by its real function, like 'Member Login' or 'Payment Gateway'."),
                _tip(Icons.list_alt, "2. Detailed feature", "Be specific: 'Login with Google OAuth' instead of just 'Login'."),
                _tip(Icons.phone_iphone, "3. Pick your platform", "Mobile, Web, or API. Each gives very different test cases."),
                _tip(Icons.lightbulb, "4. Use constraints", "Tell the AI about WCAG, SSO, session timeouts, or admin exclusions to create realistic cases."),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Example", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    const Text("Module: Member Authentication\nFeature: Login with Google OAuth\nPlatform: Web\nConstraints: Must pass WCAG 2.1 AA, test in Chrome & Safari",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accent.withOpacity(0.25))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.rocket_launch, color: AppColors.accent, size: 18),
                      SizedBox(width: 8),
                      Text("Coming Soon", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                    const SizedBox(height: 10),
                    _comingSoonItem("Bug Report"),
                    _comingSoonItem("Execution Trend Chart"),
                    _comingSoonItem("Execution Progress Dashboard"),
                  ]),
                ),
                if (widget.onStartWalkthrough != null && widget.showTourButton) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onStartWalkthrough!();
                      },
                      icon: const Icon(Icons.directions_walk, color: AppColors.accent),
                      label: const Text("Take a Quick Tour", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accent, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: AppColors.accent.withOpacity(0.06),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            if (widget.showNeverAsk) ...[
              Expanded(
                child: Row(children: [
                  SizedBox(height: 24, width: 24, child: Checkbox(value: _dontShowAgain, onChanged: (v) => setState(() => _dontShowAgain = v ?? false), activeColor: AppColors.accent, checkColor: Colors.black, side: const BorderSide(color: AppColors.textSecondary))),
                  const SizedBox(width: 8),
                  const Text("Don't show again", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
            ] else const Spacer(),
            TextButton(onPressed: () { _savePreference(); Navigator.pop(context); }, child: const Text("Got it", style: TextStyle(color: AppColors.accent))),
          ]),
        ]),
      ),
    );
  }

  Widget _tip(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppColors.accentLight, size: 20), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _comingSoonItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        const Icon(Icons.check_circle_outline, color: AppColors.accentLight, size: 14),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
