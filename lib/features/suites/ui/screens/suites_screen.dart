import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/constants.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/domain/usecases/get_history_use_case.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/features/generation/ui/screens/preview_screen.dart';
import 'package:qa_genie/presentation/screens/upgrade_coming_soon_screen.dart';

class SuitesScreen extends StatefulWidget {
  final VoidCallback? onGenerate;
  const SuitesScreen({super.key, this.onGenerate});
  @override State<SuitesScreen> createState() => SuitesScreenState();
}
class SuitesScreenState extends State<SuitesScreen> {
  final _historyUseCase = GetHistoryUseCase();
  late Future<List<Map<String,dynamic>>> _suitesFuture;
  bool _isPro = false;

  @override void initState() {
    super.initState();
    _suitesFuture = _historyUseCase.execute();
    _checkPro();
  }

  Future<void> _checkPro() async {
    final pro = await UsageManager.isPro();
    if (mounted) setState(() => _isPro = pro);
  }

  void refresh() {
    _suitesFuture = _historyUseCase.execute();
    setState(() {});
  }

  Future<bool?> _confirmDelete(int id) async {
    return showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface, title: const Text("Delete Suite?", style: TextStyle(color: Colors.white)),
      content: const Text("All test cases will be permanently deleted.", style: TextStyle(color: AppColors.textSecondary)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: AppColors.error)))],
    ));
  }

  Future<void> _deleteSuite(int id) async {
    await DatabaseService.deleteSuite(id);
    refresh();
  }

  Future<void> _renameSuite(int id, String current) async {
    final ctrl = TextEditingController(text: current);
    final newName = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface, title: const Text("Rename Suite", style: TextStyle(color: Colors.white)),
      content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text("Rename"))],
    ));
    if (newName != null && newName.isNotEmpty) {
      final db = await DatabaseService.db;
      await db.update('suites', {'moduleName': newName}, where: 'id = ?', whereArgs: [id]);
      refresh();
    }
  }

  Widget _adPlaceholder() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: AppColors.card, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 4,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.ad_units, color: AppColors.warning, size: 28)),
          title: const Text("Sponsored", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          subtitle: const Text("Ad", style: TextStyle(color: AppColors.textHint, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _proBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        color: AppColors.card, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.stars, color: AppColors.warning, size: 32), const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Unlock Pro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("20 requests/day · Unlimited exports", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ])),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeComingSoonScreen())),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Upgrade Now", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 10),

            ],
          ),
        ),
      ),
    );
  }

  Widget _suiteCard(Map<String, dynamic> s) {
    final id = s['id'] as int;
    return Dismissible(
      key: Key(id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete, color: Colors.white)),
      confirmDismiss: (_) => _confirmDelete(id),
      onDismissed: (_) => _deleteSuite(id),
      child: Card(
        color: AppColors.card, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 4,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.folder, color: AppColors.accent)),
          title: Text("${s['moduleName']} · ${s['feature']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text("${s['platform']} · ${_fmtDate(s['created_at'])}", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          trailing: PopupMenuButton(
            itemBuilder: (_) => [const PopupMenuItem(value: 'rename', child: Text("Rename")), const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red)))],
            onSelected: (action) { if (action == 'rename') _renameSuite(id, s['moduleName']??''); else _deleteSuite(id); },
          ),
          onTap: () async {
            final cases = await DatabaseService.getTestCasesForSuite(id);
            if (mounted) {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => PreviewScreen(testCases: cases, moduleName: s['moduleName']??'', feature: s['feature']??'', platform: s['platform']??'', suiteId: id)));
              refresh();
            }
          },
        ),
      ),
    );
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String,dynamic>>>(
              future: _suitesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                final suites = snapshot.data ?? [];
                if (suites.isEmpty) {
                  // Empty state
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (!_isPro) _adPlaceholder(),
                      const SizedBox(height: 24),
                      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.folder_open, size: 64, color: AppColors.textHint), const SizedBox(height: 16),
                        Text("No test suites yet", style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => widget.onGenerate?.call(),
                          icon: const Icon(Icons.bolt, color: Colors.black),
                          label: const Text("Generate now", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 4),
                        ),
                      ])),
                    ],
                  );
                }

                final children = <Widget>[];
                children.add(_suiteCard(suites.first));
                if (!_isPro) children.add(_adPlaceholder());
                for (int i = 1; i < suites.length; i++) {
                  children.add(_suiteCard(suites[i]));
                }

                return RefreshIndicator(
                  onRefresh: () async => refresh(),
                  child: ListView(padding: const EdgeInsets.all(16), children: children),
                );
              },
            ),
          ),
          // Always show pro banner at the bottom if not pro
          // Caption – always visible
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              "Your data stays local.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (!_isPro) _proBanner(),
        ],
      ),
    );
  }

  String _fmtDate(String? iso) { if (iso == null) return ''; final d = DateTime.tryParse(iso); return d == null ? '' : "${d.day}/${d.month}/${d.year}"; }
}
