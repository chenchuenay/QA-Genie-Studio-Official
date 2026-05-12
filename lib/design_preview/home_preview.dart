import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:qa_app/app/theme/constants_premium.dart';

class HomePreview extends StatefulWidget {
  const HomePreview({super.key});
  @override State<HomePreview> createState() => _HomePreviewState();
}

class _HomePreviewState extends State<HomePreview> {
  final mCtrl = TextEditingController(), fCtrl = TextEditingController(), cCtrl = TextEditingController();
  String platform = "Web";

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            const Text("SPECIFICATION", style: AppText.section),
            const SizedBox(height: AppSpacing.lg),
            _input("Module Name *", "e.g. User Authentication", mCtrl, maxLength: 40),
            const SizedBox(height: AppSpacing.md),
            _input("Feature *", "e.g. Login with Google OAuth", fCtrl, maxLength: 70),
            const SizedBox(height: AppSpacing.lg),
            const Text("Platform", style: AppText.label),
            const SizedBox(height: AppSpacing.sm),
            _platformSelector(),
            const SizedBox(height: AppSpacing.lg),
            _constraintsField(),
            const SizedBox(height: AppSpacing.xl),
            _generateButton(),
          ]),
        ),
      ),
    );
  }

  Widget _input(String label, String hint, TextEditingController ctrl, {int? maxLength}) {
    return TextFormField(
      controller: ctrl,
      style: AppText.input,
      maxLength: maxLength,
      maxLengthEnforcement: maxLength != null ? MaxLengthEnforcement.enforced : MaxLengthEnforcement.none,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppText.label,
        hintText: hint,
        hintStyle: AppText.hint,
        filled: true,
        fillColor: AppColors.input,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: const BorderSide(color: Color(0xFF2A3140))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: const BorderSide(color: Color(0xFF3DDCFF), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _platformSelector() {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1),
      ),
      child: Row(children: ["Mobile", "Web", "API"].map((p) {
        final sel = platform == p;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => platform = p),
            child: Container(
              decoration: BoxDecoration(
                gradient: sel ? const LinearGradient(colors: [Color(0xFF14D8F5), Color(0xFF57E7FF)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: Text(p, style: TextStyle(color: sel ? const Color(0xFF07131A) : AppColors.textTertiary, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList()),
    );
  }

  Widget _constraintsField() {
    return TextFormField(
      controller: cCtrl,
      maxLines: 3,
      maxLength: 100,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      style: AppText.input,
      decoration: InputDecoration(
        hintText: "e.g. Must support WCAG 2.1 AA, test on Chrome & Safari...",
        hintStyle: AppText.hint,
        filled: true,
        fillColor: AppColors.input,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: const BorderSide(color: Color(0xFF2A3140))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: const BorderSide(color: Color(0xFF3DDCFF), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        counterStyle: AppText.hint,
      ),
    );
  }

  Widget _generateButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF14D8F5), Color(0xFF57E7FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: [BoxShadow(color: const Color(0xFF3DDCFF).withOpacity(0.18), blurRadius: 22, spreadRadius: 1)],
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
          child: const Text("Generate Batch →", style: AppText.button),
        ),
      ),
    );
  }
}
