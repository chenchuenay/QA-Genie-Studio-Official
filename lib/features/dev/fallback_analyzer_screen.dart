import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/engine/orchestrator/deterministic_engine.dart';

class FallbackAnalyzerScreen extends StatefulWidget {
  const FallbackAnalyzerScreen({super.key});
  @override
  State<FallbackAnalyzerScreen> createState() => _FallbackAnalyzerScreenState();
}

class _FallbackAnalyzerScreenState extends State<FallbackAnalyzerScreen> {
  bool _running = false;
  String? _outputPath;

  static const _scenarioCount = 100;

  static const _scenarios = [
    ('Login', 'Email Authentication', 'Mobile', ''),
    ('Login', 'Email Authentication', 'Web', 'with MFA'),
    ('Login', 'SSO Integration', 'Mobile', ''),
    ('Login', 'SSO Integration', 'Web', 'SAML 2.0'),
    ('Login', 'Biometric Auth', 'Mobile', 'Face ID'),
    ('Login', 'Password Reset', 'Web', 'email link'),
    ('Login', 'Password Reset', 'Mobile', 'SMS OTP'),
    ('Login', 'Session Management', 'Web', 'timeout 30min'),
    ('Login', 'Remember Me', 'Mobile', ''),
    ('Login', 'Account Lockout', 'Web', 'after 5 attempts'),
    ('Registration', 'Email Signup', 'Web', 'email verification'),
    ('Registration', 'Email Signup', 'Mobile', 'OTP verification'),
    ('Registration', 'OAuth Signup', 'Web', 'Google'),
    ('Registration', 'OAuth Signup', 'Mobile', 'Apple'),
    ('Registration', 'Profile Setup', 'Web', 'avatar upload'),
    ('Registration', 'Profile Setup', 'Mobile', ''),
    ('Registration', 'Terms Acceptance', 'Web', 'GDPR consent'),
    ('Registration', 'Referral Code', 'Mobile', ''),
    ('Registration', 'Email Preferences', 'Web', ''),
    ('Registration', 'Phone Verification', 'Mobile', ''),
    ('Search', 'Basic Search', 'Web', ''),
    ('Search', 'Basic Search', 'Mobile', 'voice input'),
    ('Search', 'Filter Results', 'Web', 'price range'),
    ('Search', 'Filter Results', 'Mobile', 'category'),
    ('Search', 'Sort Results', 'Web', 'by relevance'),
    ('Search', 'Sort Results', 'Mobile', 'by date'),
    ('Search', 'Auto Complete', 'Web', ''),
    ('Search', 'Auto Complete', 'Mobile', 'debounce 300ms'),
    ('Search', 'Recent Searches', 'Mobile', ''),
    ('Search', 'Saved Searches', 'Web', ''),
    ('Checkout', 'Add to Cart', 'Web', ''),
    ('Checkout', 'Add to Cart', 'Mobile', 'quick add'),
    ('Checkout', 'Remove from Cart', 'Web', ''),
    ('Checkout', 'Remove from Cart', 'Mobile', 'swipe'),
    ('Checkout', 'Update Quantity', 'Web', ''),
    ('Checkout', 'Update Quantity', 'Mobile', 'stepper'),
    ('Checkout', 'Apply Coupon', 'Web', 'percentage'),
    ('Checkout', 'Apply Coupon', 'Mobile', 'flat discount'),
    ('Checkout', 'Shipping Address', 'Web', 'international'),
    ('Checkout', 'Shipping Address', 'Mobile', 'autocomplete'),
    ('Payment', 'Credit Card', 'Web', 'Visa'),
    ('Payment', 'Credit Card', 'Mobile', 'Apple Pay'),
    ('Payment', 'UPI Payment', 'Mobile', ''),
    ('Payment', 'UPI Payment', 'Web', 'QR code'),
    ('Payment', 'Net Banking', 'Web', ''),
    ('Payment', 'Wallet Balance', 'Mobile', ''),
    ('Payment', 'Refund Processing', 'Web', ''),
    ('Payment', 'Refund Processing', 'Mobile', 'partial'),
    ('Payment', 'Invoice Download', 'Web', 'PDF'),
    ('Payment', 'Invoice Download', 'Mobile', 'email'),
    ('Profile', 'Update Name', 'Mobile', ''),
    ('Profile', 'Update Name', 'Web', 'validation special chars'),
    ('Profile', 'Change Password', 'Web', 'strength check'),
    ('Profile', 'Change Password', 'Mobile', 'biometric confirm'),
    ('Profile', 'Upload Photo', 'Mobile', 'camera'),
    ('Profile', 'Upload Photo', 'Web', 'drag drop'),
    ('Profile', 'Delete Account', 'Web', 'confirmation'),
    ('Profile', 'Delete Account', 'Mobile', 'cool down 30d'),
    ('Profile', 'Notification Settings', 'Mobile', 'push'),
    ('Profile', 'Notification Settings', 'Web', 'email'),
    ('Notifications', 'Push Notification', 'Mobile', ''),
    ('Notifications', 'Push Notification', 'Web', 'desktop'),
    ('Notifications', 'Email Notification', 'Web', 'HTML template'),
    ('Notifications', 'SMS Alert', 'Mobile', 'OTP'),
    ('Notifications', 'In App Banner', 'Mobile', ''),
    ('Notifications', 'In App Banner', 'Web', 'toast'),
    ('Notifications', 'Digest Email', 'Web', 'weekly'),
    ('Notifications', 'Quiet Hours', 'Mobile', ''),
    ('Notifications', 'Opt Out', 'Web', 'unsubscribe link'),
    ('Notifications', 'Opt Out', 'Mobile', 'settings toggle'),
    ('Admin', 'User Management', 'Web', 'pagination'),
    ('Admin', 'User Management', 'Mobile', 'search'),
    ('Admin', 'Role Assignment', 'Web', 'RBAC'),
    ('Admin', 'Role Assignment', 'Mobile', ''),
    ('Admin', 'Audit Logs', 'Web', 'date filter'),
    ('Admin', 'Audit Logs', 'Mobile', ''),
    ('Admin', 'Content Moderation', 'Web', ''),
    ('Admin', 'Content Moderation', 'Mobile', ''),
    ('Admin', 'System Settings', 'Web', 'feature flags'),
    ('Admin', 'System Settings', 'Mobile', ''),
    ('Orders', 'Order History', 'Web', 'pagination'),
    ('Orders', 'Order History', 'Mobile', 'infinite scroll'),
    ('Orders', 'Order Details', 'Web', ''),
    ('Orders', 'Order Details', 'Mobile', 'share'),
    ('Orders', 'Track Order', 'Web', 'real time map'),
    ('Orders', 'Track Order', 'Mobile', 'push updates'),
    ('Orders', 'Cancel Order', 'Web', 'reason selection'),
    ('Orders', 'Cancel Order', 'Mobile', ''),
    ('Orders', 'Return Request', 'Web', 'pickup'),
    ('Orders', 'Return Request', 'Mobile', 'drop off'),
    ('Wishlist', 'Add Item', 'Web', ''),
    ('Wishlist', 'Add Item', 'Mobile', 'swipe'),
    ('Wishlist', 'Remove Item', 'Web', ''),
    ('Wishlist', 'Remove Item', 'Mobile', 'long press'),
    ('Wishlist', 'Move to Cart', 'Web', ''),
    ('Wishlist', 'Move to Cart', 'Mobile', ''),
    ('Wishlist', 'Share Wishlist', 'Web', 'link'),
    ('Wishlist', 'Share Wishlist', 'Mobile', 'social'),
    ('Wishlist', 'Create List', 'Web', ''),
    ('Wishlist', 'Rename List', 'Mobile', ''),
  ];

  Future<void> _runAnalysis() async {
    setState(() {
      _running = true;
      _outputPath = null;
    });

    try {
      final results = <Map<String, dynamic>>[];
      for (int i = 0; i < _scenarioCount; i++) {
        final (module, feature, platform, constraints) = _scenarios[i];
        final engine = DeterministicEngine(
          module: module,
          feature: feature,
          platform: platform,
          constraints: constraints,
          targetCount: 10,
          mode: GenerationMode.core,
        );

        final stopwatch = Stopwatch()..start();
        final testCases = await engine.generate();
        stopwatch.stop();

        results.add(_scenarioToJson(i, module, feature, platform, constraints, testCases, stopwatch.elapsedMilliseconds));
      }

      final report = _buildReport(results);
      final dir = await getApplicationDocumentsDirectory();
      final outputDir = Directory(
        '${dir.path}/QA_Genie/Fallback_Analysis',
      );
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filePath = '${outputDir.path}/fallback_analysis_$timestamp.json';

      final extDir = await getExternalStorageDirectory();
      final extPath = extDir != null
          ? '${extDir.path}/fallback_analysis_$timestamp.json'
          : null;

      await Future.wait([
        File(filePath).writeAsString(jsonEncode(report)),
        if (extPath != null)
          File(extPath).writeAsString(jsonEncode(report)),
      ]);

      setState(() {
        _running = false;
        _outputPath = extPath ?? filePath;
      });
    } catch (e) {
      setState(() => _running = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Map<String, dynamic> _scenarioToJson(
    int index,
    String module,
    String feature,
    String platform,
    String constraints,
    List<FinalizedTestCase> testCases,
    int latencyMs,
  ) {
    final categories = <String, int>{};
    final sources = <String, int>{};
    for (final tc in testCases) {
      categories[tc.type] = (categories[tc.type] ?? 0) + 1;
      sources[tc.source.name] = (sources[tc.source.name] ?? 0) + 1;
    }

    return {
      'scenario_index': index + 1,
      'module': module,
      'feature': feature,
      'platform': platform,
      'constraints': constraints,
      'cases_generated': testCases.length,
      'latency_ms': latencyMs,
      'categories': categories,
      'sources': sources,
      'test_cases': testCases.map((tc) => {
        'id': tc.id,
        'title': tc.title,
        'priority': tc.priority,
        'type': tc.type,
        'source': tc.source.name,
        'preconditions': tc.preconditions,
        'testData': tc.testData,
        'steps': tc.steps.map((s) => {
          'action': s.action,
          'data': s.data,
          'expected': s.expected,
        }).toList(),
        'expectedResult': tc.expectedResult,
      }).toList(),
    };
  }

  Map<String, dynamic> _buildReport(List<Map<String, dynamic>> results) {
    int totalCases = 0;
    int totalLatency = 0;
    final sourceCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    int minCases = 1000;
    int maxCases = 0;

    for (final r in results) {
      final count = r['cases_generated'] as int;
      totalCases += count;
      totalLatency += r['latency_ms'] as int;
      if (count < minCases) minCases = count;
      if (count > maxCases) maxCases = count;

      final sources = r['sources'] as Map<String, dynamic>;
      for (final entry in sources.entries) {
        sourceCounts[entry.key] = (sourceCounts[entry.key] ?? 0) + (entry.value as int);
      }

      final cats = r['categories'] as Map<String, dynamic>;
      for (final entry in cats.entries) {
        categoryCounts[entry.key] = (categoryCounts[entry.key] ?? 0) + (entry.value as int);
      }
    }

    return {
      'analysis_metadata': {
        'tool': 'QA Genie Fallback Analyzer',
        'generated_at': DateTime.now().toIso8601String(),
        'total_scenarios': _scenarioCount,
        'engine': 'DeterministicEngine (FallbackStage)',
      },
      'summary': {
        'total_scenarios': _scenarioCount,
        'total_test_cases': totalCases,
        'avg_cases_per_scenario': (totalCases / _scenarioCount).toStringAsFixed(1),
        'min_cases_per_scenario': minCases,
        'max_cases_per_scenario': maxCases,
        'avg_latency_ms': (totalLatency / _scenarioCount).toStringAsFixed(0),
        'total_latency_ms': totalLatency,
        'source_distribution': sourceCounts,
        'category_distribution': categoryCounts,
      },
      'scenarios': results,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Fallback Quality Analyzer', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offline Fallback Analysis',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Runs $_scenarioCount offline scenarios using DeterministicEngine. '
                      'No cloud calls — zero cost. Writes full results as JSON for AI analysis.',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _statRow('Scenarios', '$_scenarioCount'),
                    _statRow('Cases per scenario', '10'),
                    _statRow('Total cases', '${_scenarioCount * 10}'),
                    _statRow('Engine', 'DeterministicEngine'),
                    _statRow('Cost', 'Free (no API calls)'),
                  ],
                ),
              ),
            ),
            if (_outputPath != null) ...[
              const SizedBox(height: 16),
              Card(
                color: AppColors.success.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success, size: 20),
                          SizedBox(width: 8),
                          Text('Analysis complete!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'File saved to:\n$_outputPath',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'adb pull /storage/emulated/0/Android/data/com.enaykumar.qagenie/files/fallback_analysis_*.json .',
                          style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _running ? null : _runAnalysis,
                icon: _running
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.play_arrow),
                label: Text(_running ? 'Running $_scenarioCount scenarios...' : 'Run $_scenarioCount Scenarios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
