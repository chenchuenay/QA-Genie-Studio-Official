import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/theme/app_spacing.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';

class ReportIssueScreen extends StatefulWidget {
  final String? screen;
  const ReportIssueScreen({super.key, this.screen});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _myFeedbacksKey = GlobalKey<_MyFeedbacksViewState>();

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

  void _onReportSubmitted() {
    _tabController.animateTo(1);
    _myFeedbacksKey.currentState?._loadFeedbacks();
  }

  @override
  Widget build(BuildContext context) {
    // Guests see a professional message instead of the report form
    if (AuthService.isGuest) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Support'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: AppColors.textHint),
                const SizedBox(height: 20),
                const Text(
                  'Sign in to submit a report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Only signed-in members can submit a report. '
                  'Sign in with Google to share your feedback and track its status.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Support'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Report Issue'),
            Tab(text: 'My Feedbacks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportFormView(screen: widget.screen, onSubmitted: _onReportSubmitted),
          _MyFeedbacksView(key: _myFeedbacksKey, onShareFeedback: () => _tabController.animateTo(0)),
        ],
      ),
    );
  }
}

class _MyFeedbacksView extends StatefulWidget {
  final VoidCallback? onShareFeedback;
  const _MyFeedbacksView({super.key, this.onShareFeedback});

  @override
  State<_MyFeedbacksView> createState() => _MyFeedbacksViewState();
}

class _MyFeedbacksViewState extends State<_MyFeedbacksView> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = false;

  /// Converts a Firestore Timestamp (serialized as Map with _seconds on the
  /// wire) or an ISO string to a stable ISO string. Falls back to now.
  String _parseTimestamp(dynamic ts) {
    if (ts is String) return ts;
    if (ts is Map) {
      final secs = ts['_seconds'];
      if (secs is int) {
        return DateTime.fromMillisecondsSinceEpoch(secs * 1000, isUtc: true).toIso8601String();
      }
    }
    return DateTime.now().toIso8601String();
  }

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    final db = await DatabaseService.db;

    try {
      final result = await FunctionsService.call(
        functionName: 'getMyIssueReports',
        timeout: const Duration(seconds: 10),
      );

      if (result['success'] == false) {
        final errorMsg = result['error']?['message'] ?? 'Unknown error';
        if (mounted) {
          showBlurredDialog(
            context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Sync Failed', style: TextStyle(color: Colors.white)),
              content: Text(
                errorMsg,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(color: AppColors.accent)),
                ),
              ],
            ),
          );
        }
      } else {
        final remoteReports = result['reports'] as List? ?? [];

        // Collect all remote IDs for orphan detection
        final remoteIds = remoteReports
            .where((r) => r is Map && r['id'] is String)
            .map((r) => r['id'] as String)
            .toSet();

        final existing = await db.query('reported_issues');
        final localIds = existing
            .map((e) => e['firestoreId'] as String?)
            .where((id) => id != null && id.isNotEmpty)
            .toSet();

        for (final remote in remoteReports) {
          if (remote is Map) {
            final remoteId = remote['id'] as String?;
            if (remoteId == null || remoteId.isEmpty) continue;
            final remoteStatus = remote['status'] as String? ?? 'open';
            final remoteTitle = remote['title'] as String? ?? '';
            final remoteType = remote['issueType'] as String? ?? '';

            if (!localIds.contains(remoteId)) {
              await DatabaseService.insertReportedIssue({
                'firestoreId': remoteId,
                'issueType': remoteType,
                'title': remoteTitle,
                'description': remote['description'] ?? '',
                'status': remoteStatus,
                'createdAt': _parseTimestamp(remote['createdAt']),
                'isSynced': 1,
              });
            } else {
              for (int i = 0; i < existing.length; i++) {
                if (existing[i]['firestoreId'] == remoteId) {
                  final localId = existing[i]['id'];
                  if (localId is int) {
                    await db.update(
                      'reported_issues',
                      {
                        'title': remoteTitle,
                        'issueType': remoteType,
                        'status': remoteStatus,
                        'isSynced': 1,
                      },
                      where: 'id = ?',
                      whereArgs: [localId],
                    );
                  }
                  break;
                }
              }
            }
          }
        }

        // Delete orphaned local reports (e.g. when a report is re-serialized on move)
        for (final local in existing) {
          final localId = local['firestoreId'] as String?;
          if (localId != null && localId.isNotEmpty && !remoteIds.contains(localId)) {
            await db.delete('reported_issues', where: 'id = ?', whereArgs: [local['id']]);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showBlurredDialog(
          context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Sync Failed', style: TextStyle(color: Colors.white)),
            content: Text(
              e.toString(),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        );
      }
    }

    final data = await db.query('reported_issues', orderBy: 'createdAt DESC');
    if (mounted) setState(() { _feedbacks = data; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_feedbacks.isEmpty && !_isLoading) {
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
                onPressed: widget.onShareFeedback ?? () => DefaultTabController.of(context).animateTo(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: const Text(
                  'Share Feedback',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => _loadFeedbacks(),
                icon: const Icon(Icons.sync, color: AppColors.accent, size: 18),
                label: const Text(
                  'Sync from cloud',
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadFeedbacks(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _feedbacks.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index < _feedbacks.length) {
            final item = _feedbacks[index];
            final status = item['status'] as String? ?? 'open';
            final statusColor = switch (status) {
              'working' => const Color(0xFF42A5F5),
              'fixed' => const Color(0xFF66BB6A),
              _ => const Color(0xFFFFCA28),
            };
            final helperText = switch ((item['issueType'] as String?) ?? '') {
              'Bug' => status == 'fixed' ? 'Reflects in next update' : status == 'working' ? 'Being investigated' : 'Awaiting review',
              'Feedback' => status == 'fixed' ? 'Reflects in next update' : status == 'working' ? 'Under review' : 'Awaiting review',
              'Feature Request' => status == 'fixed' ? 'Planned for upcoming release' : status == 'working' ? 'Being evaluated' : 'Under consideration',
              'Generation Issue' => status == 'fixed' ? 'Improvement shipped' : status == 'working' ? 'Being investigated' : 'Awaiting review',
              'Export Issue' => status == 'fixed' ? 'Fix shipped' : status == 'working' ? 'Being investigated' : 'Awaiting review',
              'UI Issue' => status == 'fixed' ? 'Fix shipped' : status == 'working' ? 'Being investigated' : 'Awaiting review',
              _ => status == 'fixed' ? 'Resolved' : status == 'working' ? 'In progress' : 'Pending',
            };
            return Card(
              color: AppColors.surface,
              child: ListTile(
                title: Text(
                  item['title'] ?? '',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${item['issueType']}',
                          style: const TextStyle(color: AppColors.textHint),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status.substring(0, 1).toUpperCase() + status.substring(1),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      helperText,
                      style: TextStyle(color: statusColor.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }
          // Last item: sync button at bottom
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: TextButton.icon(
                onPressed: _isLoading ? null : () => _loadFeedbacks(),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    : const Icon(Icons.sync, color: AppColors.accent, size: 18),
                label: Text(
                  _isLoading ? 'Syncing...' : 'Sync',
                  style: const TextStyle(color: AppColors.accent),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReportFormView extends StatefulWidget {
  final String? screen;
  final VoidCallback? onSubmitted;
  const _ReportFormView({this.screen, this.onSubmitted});

  @override
  State<_ReportFormView> createState() => _ReportFormViewState();
}

class _ReportFormViewState extends State<_ReportFormView> {
  final _formKey = GlobalKey<FormState>();
  String _issueType = 'Feedback';
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
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (!UsageManager.canGiveFeedback) {
      if (mounted) {
        showBlurredDialog(context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Feedback Unavailable', style: TextStyle(color: Colors.white)),
            content: const Text('Feedback submission is limited to signed-in members. Sign in with Google to share your thoughts.', style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    if (!await NetworkGuard.ensureProductionOnline(context)) return;

    try {
      final member = AuthService.currentMember;
      final uid = member?.uid ?? 'unknown';

      String? platform, deviceModel, appVersion;
      if (_includeDeviceInfo) {
        final device = await DeviceInfoPlugin().androidInfo;
        final package = await PackageInfo.fromPlatform();
        platform = 'Android';
        deviceModel = device.model;
        appVersion = package.version;
      }

      try {
        final result = await FunctionsService.call(
          functionName: 'submitIssueReport',
          payload: {
            'uid': uid,
            'issueType': _issueType,
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'platform': platform,
            'deviceModel': deviceModel,
            'appVersion': appVersion,
            'screen': widget.screen ?? 'ReportIssueScreen',
          },
        );

        final success = result['success'] != false;
        final firestoreId = result['id'] as String?;
        if (success && firestoreId != null && firestoreId.isNotEmpty) {
          await DatabaseService.insertReportedIssue({
            'firestoreId': firestoreId,
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
          widget.onSubmitted?.call();

          if (!mounted) return;
          await showBlurredDialog(context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                'Thank you!',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Your feedback has been submitted successfully.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _titleController.clear();
                    _descriptionController.clear();
                    setState(() => _issueType = 'Feedback');
                    widget.onSubmitted?.call();
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to submit: $e');
      }
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
            const Text('Help improve QA Genie.', style: AppText.body),
            const SizedBox(height: AppSpacing.md),
            const Text('Issue Type', style: AppText.label),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _issueType,
              items: _issueTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
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
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Description', style: AppText.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 100,
              decoration: InputDecoration(
                hintText:
                    'Describe what happened, steps to reproduce, etc. (optional)',
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
                  onChanged: (val) =>
                      setState(() => _includeDeviceInfo = val ?? true),
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
                child: const Text('Send Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
