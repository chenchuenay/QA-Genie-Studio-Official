import 'package:flutter/material.dart';
import 'package:qa_app/core/config/app_config.dart';
import 'package:qa_app/core/theme/constants.dart';
import 'package:qa_app/domain/usecases/get_history_use_case.dart';
import 'package:qa_app/data/sources/local/database_service.dart';
import 'package:qa_app/features/suites/ui/screens/history_suite_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _getHistoryUseCase = GetHistoryUseCase();
  late Future<List<Map<String, dynamic>>> _suitesFuture;

  @override
  void initState() {
    super.initState();
    _loadSuites();
  }

  void _loadSuites() => _suitesFuture = _getHistoryUseCase.execute();

  Future<void> _deleteSuite(int suiteId) async {
    await DatabaseService.deleteSuite(suiteId);
    _loadSuites();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("History", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _suitesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No test suites yet",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Generate your first set"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (AppConfig.isProduction) _buildProBanner(),
                ],
              ),
            );
          }
          final suites = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadSuites();
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: suites.length,
                    itemBuilder: (context, index) {
                      final suite = suites[index];
                      final id = suite['id'] as int;
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
                        confirmDismiss: (direction) async =>
                            await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                title: const Text(
                                  "Delete Suite",
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  "Delete this test suite permanently?",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        onDismissed: (_) => _deleteSuite(id),
                        child: Card(
                          color: AppColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.folder,
                                color: AppColors.accent,
                              ),
                            ),
                            title: Text(
                              "${suite['moduleName']} · ${suite['feature']}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${suite['platform']} · ${_formatDate(suite['created_at'])}",
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.white54,
                            ),
                            onTap: () async {
                              final cases =
                                  await DatabaseService.getTestCasesForSuite(
                                    id,
                                  );
                              if (mounted)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HistorySuiteDetailScreen(
                                      testCases: cases,
                                      moduleName: suite['moduleName'] ?? '',
                                      feature: suite['feature'] ?? '',
                                      platform: suite['platform'] ?? '',
                                      suiteId: id,
                                    ),
                                  ),
                                );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProBanner() => Card(
    color: AppColors.card,
    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.stars, color: AppColors.warning, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Unlock Pro",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Unlimited generations, exports & ad-free",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/upgrade'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text("Upgrade"),
          ),
        ],
      ),
    ),
  );

  String _formatDate(String? iso) {
    if (iso == null) return "";
    final d = DateTime.tryParse(iso);
    if (d == null) return "";
    return "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }
}
