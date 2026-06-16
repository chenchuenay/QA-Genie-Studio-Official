import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import '../../../monetization/ui/upgrade_screen.dart';
import 'package:qa_genie/app/startup/app_dependencies.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/shared/widgets/native_ad_widget.dart';
import 'package:qa_genie/features/monetization/ads/ad_units.dart';
import 'package:qa_genie/features/monetization/ads/ad_manager.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/features/suites/ui/screens/suite_preview_screen.dart'; // ✅ correct import

class SuitesScreen extends StatefulWidget {
  final VoidCallback? onGenerate;

  const SuitesScreen({super.key, this.onGenerate});

  @override
  State<SuitesScreen> createState() => SuitesScreenState();
}

class SuitesScreenState extends State<SuitesScreen> {
  final _historyUseCase = AppDependencies.getHistoryUseCase;
  late Future<List<Map<String, dynamic>>> _suitesFuture;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    AdManager().loadRewardedAd(adUnitId: AdUnits.rewardedTcExport);
    _refreshSuites();
    _checkPro();
  }

  void _refreshSuites() {
    setState(() {
      _suitesFuture = _historyUseCase.getAllSuites();
    });
  }

  Future<void> _checkPro() async {
    final pro = await UsageManager.isPro();
    if (!mounted) return;
    setState(() => _isPro = pro);
  }

  void refresh() {
    _refreshSuites();
  }

  Future<bool?> _confirmDelete(int id) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Suite?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'All test cases will be permanently deleted.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSuite(int id) async {
    await DatabaseService.deleteSuite(id);
    refresh();
  }

  Future<void> _renameSuite(int id, String current) async {
    final ctrl = TextEditingController(text: current);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Rename Suite',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    final db = await DatabaseService.db;
    await db.update(
      'suites',
      {'moduleName': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
    refresh();
  }

  Widget _adPlaceholder() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: AppColors.card,
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Stack(
          children: [
            const SizedBox(
              height: 90,
              width: double.infinity,
              child: NativeAdWidget(),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: const Text(
                  'AD',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suiteCard(Map<String, dynamic> s) {
    final id = s['id'] as int;
    return Dismissible(
      key: Key(id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(id),
      onDismissed: (_) => _deleteSuite(id),
      child: Card(
        color: AppColors.card,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.folder, color: AppColors.accent),
          ),
          title: Text(
            '${s['moduleName']} · ${s['feature']}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${s['platform']} · ${_fmtDate(s['created_at'])}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: PopupMenuButton<String>(
            color: AppColors.surface,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rename', child: Text('Rename')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (action) async {
              if (action == 'rename') {
                _renameSuite(id, s['moduleName'] ?? '');
              } else if (action == 'delete') {
                final confirmed = await _confirmDelete(id);
                if (confirmed == true) _deleteSuite(id);
              }
            },
          ),
          onTap: () async {
            final canonicalCases = await DatabaseService.getTestCasesForSuite(
              id,
            );
            final session = GenerationSession(
              traceId:
                  'HISTORICAL_LOAD_${DateTime.now().millisecondsSinceEpoch}',
              testCases: canonicalCases,
              auditReport: const PipelineAuditReport(
                traceId: 'HISTORICAL_LOAD',
              ),
            );
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SuitePreviewScreen(
                  session: session,
                  moduleName: s['moduleName'] ?? 'Unknown',
                  feature: s['feature'] ?? 'Unknown',
                  platform: s['platform'] ?? 'Web',
                  suiteId: id,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _suitesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                final suites = snapshot.data ?? [];
                if (suites.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (!_isPro) _adPlaceholder(),
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.folder_open,
                              size: 64,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No test suites yet',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => widget.onGenerate?.call(),
                              icon: const Icon(Icons.bolt, color: Colors.black),
                              label: const Text(
                                'Generate now',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 14,
                                ),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                final children = <Widget>[];
                children.add(_suiteCard(suites.first));
                if (!_isPro) children.add(_adPlaceholder());
                for (int i = 1; i < suites.length; i++)
                  children.add(_suiteCard(suites[i]));

                return RefreshIndicator(
                  onRefresh: () async {
                    refresh();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: children,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              'Your data stays local.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (!_isPro) const _ProBanner(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _ProBanner extends StatelessWidget {
  const _ProBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: AppColors.card,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.stars, color: AppColors.accent, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Unlock Pro · 15 requests/day',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Upgrade',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
