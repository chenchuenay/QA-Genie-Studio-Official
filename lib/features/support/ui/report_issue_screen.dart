import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_spacing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/app/theme/app_colors.dart';

class ReportIssueScreen extends StatefulWidget {
  final String? screen;
  const ReportIssueScreen({super.key, this.screen});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Support'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Report Issue'), Tab(text: 'My Feedbacks')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportFormView(screen: widget.screen),
          const _MyFeedbacksView(),
        ],
      ),
    );
  }
}

class _MyFeedbacksView extends StatefulWidget {
  const _MyFeedbacksView();

  @override
  State<_MyFeedbacksView> createState() => _MyFeedbacksViewState();
}

class _MyFeedbacksViewState extends State<_MyFeedbacksView> {
  List<Map<String, dynamic>> _feedbacks = [];

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    final db = await DatabaseService.db;
    final data = await db.query('reported_issues', orderBy: 'createdAt DESC');
    
    // Refresh status from Firestore if > 14 days
    List<Map<String, dynamic>> updatedData = List.from(data);
    for (int i = 0; i < updatedData.length; i++) {
      final item = Map<String, dynamic>.from(updatedData[i]);
      final firestoreId = item['firestoreId'];
      final lastSync = item['lastSyncAttempt'] != null ? DateTime.parse(item['lastSyncAttempt']) : null;

      if (firestoreId != null && (lastSync == null || DateTime.now().difference(lastSync).inDays >= 14)) {
        try {
          final doc = await FirebaseFirestore.instance.collection('issue_reports').doc(firestoreId).get();
          if (doc.exists) {
            final newStatus = doc.data()?['status'] ?? 'open';
            await DatabaseService.updateIssueStatus(item['id'], newStatus);
            item['status'] = newStatus;
            updatedData[i] = item;
          }
        } catch (e) {
          debugPrint('Sync failed: $e');
        }
      }
    }
    
    if (mounted) setState(() => _feedbacks = updatedData);
  }

  @override
  Widget build(BuildContext context) {
    if (_feedbacks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No feedback shared yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => DefaultTabController.of(context).animateTo(0),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                child: const Text('Share Feedback', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _feedbacks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _feedbacks[index];
        return Card(
          color: AppColors.surface,
          child: ListTile(
            title: Text(item['title'], style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              '${item['issueType']} • Status: ${item['status']}',
              style: const TextStyle(color: AppColors.textHint),
            ),
          ),
        );
      },
    );
  }
}

class _ReportFormView extends StatefulWidget {
  final String? screen;
  const _ReportFormView({this.screen});

  @override
  State<_ReportFormView> createState() => _ReportFormViewState();
}

class _ReportFormViewState extends State<_ReportFormView> {
  final _formKey = GlobalKey<FormState>();
  String _issueType = 'Bug';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _includeDeviceInfo = true;
  bool _isSubmitting = false;

  final List<String> _issueTypes = [
    'Bug',
    'Feedback',
    'Feature Request',
    'Generation Issue',
    'Export Issue',
    'UI Issue',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final user = AuthService.currentUser;
      final uid = user?.uid ?? 'unknown';

      String? platform, deviceModel, appVersion;
      if (_includeDeviceInfo) {
        final device = await DeviceInfoPlugin().androidInfo;
        final package = await PackageInfo.fromPlatform();
        platform = 'Android';
        deviceModel = device.model;
        appVersion = package.version;
      }

      final reportData = {
        'uid': uid,
        'issueType': _issueType,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'platform': platform,
        'deviceModel': deviceModel,
        'appVersion': appVersion,
        'status': 'open',
        'screen': widget.screen ?? 'ReportIssueScreen',
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        final docRef = await FirebaseFirestore.instance
            .collection('issue_reports')
            .add(reportData);
        await DatabaseService.insertReportedIssue({
          'firestoreId': docRef.id,
          'issueType': _issueType,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': 'open',
          'platform': platform,
          'deviceModel': deviceModel,
          'appVersion': appVersion,
          'screen': widget.screen ?? 'ReportIssueScreen',
          'isSynced': 1,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        await DatabaseService.insertReportedIssue({
          'issueType': _issueType,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': 'open',
          'platform': platform,
          'deviceModel': deviceModel,
          'appVersion': appVersion,
          'screen': widget.screen ?? 'ReportIssueScreen',
          'isSynced': 0,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Thank you!', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Your feedback has been submitted successfully.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Close', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Help us improve QA Genie.', style: AppText.body),
            const SizedBox(height: AppSpacing.md),
            const Text('Issue Type', style: AppText.label),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _issueType,
              items: _issueTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (val) => setState(() => _issueType = val!),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Title', style: AppText.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              maxLength: 40,
              decoration: InputDecoration(
                hintText: 'Short summary of the issue',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Description', style: AppText.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Describe what happened, steps to reproduce, etc. (optional)',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Checkbox(
                  value: _includeDeviceInfo,
                  onChanged: (val) => setState(() => _includeDeviceInfo = val ?? true),
                  activeColor: AppColors.accent,
                ),
                const Text('Include device information', style: AppText.body),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
