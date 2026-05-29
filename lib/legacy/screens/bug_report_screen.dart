import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/core/error/ui_error_service.dart';

class BugReportScreen extends StatefulWidget {
  final bool firebaseReady;
  const BugReportScreen({super.key, this.firebaseReady = false});
  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final _descController = TextEditingController();
  final _stepsController = TextEditingController();
  String _selectedType = "Crash";
  final _types = ["Crash", "Wrong Output", "UI Issue", "Performance", "Other"];
  bool _submitting = false;

  Future<void> _submit() async {
    if (_descController.text.trim().isEmpty) return;
    if (!widget.firebaseReady) {
      UiErrorService.logAndShow(
        context: context,
        source: ErrorSource.bugReportUi,
        screen: 'BugReportScreen',
        stage: ErrorStage.submit,
        severity: ErrorSeverity.warning,
        userMessage: 'Firebase not connected. Cannot submit.',
        error: 'Firebase not connected',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      // Cloud bug reports are intentionally disabled for the local beta build.
      // Firebase submission can be restored when backend setup is enabled.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _descController.clear();
      _stepsController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bug report captured for this beta session."),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e, stack) {
      UiErrorService.logAndShow(
        context: context,
        source: ErrorSource.bugReportUi,
        screen: 'BugReportScreen',
        stage: ErrorStage.submit,
        severity: ErrorSeverity.error,
        userMessage: 'Submission failed: $e',
        error: e,
        stack: stack,
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Bug Report", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Submit a Bug",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              dropdownColor: AppColors.card,
              decoration: const InputDecoration(
                labelText: "Bug Type",
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              items: _types
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        t,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Description *",
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _stepsController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Steps to Reproduce (optional)",
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Report"),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Your previous reports",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Report history will be available when Firebase is connected.",
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
