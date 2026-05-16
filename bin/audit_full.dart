import 'dart:convert';
import 'dart:io';

import 'package:qa_genie/engine/generation_service.dart';

Future<void> main() async {
  final started = DateTime.now().toUtc();

  final gen = GenerationService();

  final runs = [
    {
      'mode': 'CORE',
      'platform': 'Web',
      'module': 'Authentication',
      'feature': 'Login',
      'maxCases': 10,
    },
    {
      'mode': 'CORE',
      'platform': 'Mobile',
      'module': 'Profile',
      'feature': 'Edit Profile',
      'maxCases': 10,
    },
    {
      'mode': 'CORE',
      'platform': 'API',
      'module': 'Orders',
      'feature': 'Checkout',
      'maxCases': 10,
    },
    {
      'mode': 'PRO',
      'platform': 'Web',
      'module': 'Payments',
      'feature': 'Subscription Upgrade',
      'maxCases': 20,
    },
    {
      'mode': 'PRO',
      'platform': 'Mobile',
      'module': 'Wallet',
      'feature': 'Send Money',
      'maxCases': 20,
    },
    {
      'mode': 'PRO',
      'platform': 'API',
      'module': 'Inventory',
      'feature': 'Stock Sync',
      'maxCases': 20,
    },
  ];

  final summary = StringBuffer();
  final alerts = <String>[];

  summary.writeln('# QA GENIE HEADLESS AUDIT');
  summary.writeln('');
  summary.writeln('Timestamp: ${started.toIso8601String()}');
  summary.writeln('');

  for (final cfg in runs) {
    final result = await gen.execute(
      module: cfg['module'] as String,
      feature: cfg['feature'] as String,
      platform: cfg['platform'] as String,
      maxCases: cfg['maxCases'] as int,
    );

    final cases = result.cases;

    final uniqueTitles = cases
        .map((e) => e.title.trim().toLowerCase())
        .toSet()
        .length;

    final duplicateTitles = cases.length - uniqueTitles;

    final high = cases.where((e) => e.priority == 'High').length;

    final medium = cases.where((e) => e.priority == 'Medium').length;

    final low = cases.where((e) => e.priority == 'Low').length;

    const banned = [
      'system behaves correctly',
      'expected outcome',
      'appropriate response',
      'observe the final state',
      'appropriate follow-up view displayed',
    ];

    int fillerCount = 0;

    for (final tc in cases) {
      final combined = '${tc.title} ${tc.expectedResult}'.toLowerCase();

      for (final phrase in banned) {
        if (combined.contains(phrase)) {
          fillerCount++;
        }
      }
    }

    final realismScore = ((uniqueTitles / cases.length) * 10)
        .clamp(0, 10)
        .toStringAsFixed(1);

    final pass =
        duplicateTitles == 0 && fillerCount == 0 && medium > 0 && low > 0;

    if (!pass) {
      alerts.add(
        '[${cfg['mode']}/${cfg['platform']}] duplicate=$duplicateTitles filler=$fillerCount high=$high medium=$medium low=$low',
      );
    }

    summary.writeln('## ${cfg['mode']} — ${cfg['platform']}');
    summary.writeln('');

    summary.writeln('| Metric | Value |');
    summary.writeln('|---|---|');
    summary.writeln('| Generated Cases | ${cases.length} |');
    summary.writeln('| Unique Titles | $uniqueTitles |');
    summary.writeln('| Duplicate Titles | $duplicateTitles |');
    summary.writeln('| High | $high |');
    summary.writeln('| Medium | $medium |');
    summary.writeln('| Low | $low |');
    summary.writeln('| Filler Hits | $fillerCount |');
    summary.writeln('| Realism Score | $realismScore/10 |');
    summary.writeln('| Status | ${pass ? 'PASS' : 'FAIL'} |');
    summary.writeln('');

    final historyEntry = {
      'timestamp': started.toIso8601String(),
      'mode': cfg['mode'],
      'platform': cfg['platform'],
      'generated': cases.length,
      'uniqueTitles': uniqueTitles,
      'duplicates': duplicateTitles,
      'high': high,
      'medium': medium,
      'low': low,
      'fillerCount': fillerCount,
      'realismScore': realismScore,
      'status': pass ? 'PASS' : 'FAIL',
    };

    File(
      'test_results/audit_history.jsonl',
    ).writeAsStringSync('${jsonEncode(historyEntry)}\n', mode: FileMode.append);

    final csvLine =
        '${started.toIso8601String()},${cfg['mode']},${cfg['platform']},${cases.length},$uniqueTitles,$duplicateTitles,$high,$medium,$low,$fillerCount,$realismScore,${pass ? 'PASS' : 'FAIL'}\n';

    final csvFile = File('test_results/metrics.csv');

    if (!csvFile.existsSync()) {
      csvFile.writeAsStringSync(
        'timestamp,mode,platform,generated,uniqueTitles,duplicates,high,medium,low,fillerCount,realismScore,status\n',
      );
    }

    csvFile.writeAsStringSync(csvLine, mode: FileMode.append);
  }

  if (alerts.isEmpty) {
    alerts.add('NO REGRESSIONS DETECTED');
  }

  File('test_results/latest_summary.md').writeAsStringSync(summary.toString());

  File(
    'test_results/regression_alerts.md',
  ).writeAsStringSync(alerts.join('\n'));

  print('');
  print('=====================================');
  print('QA GENIE AUDIT COMPLETE');
  print('=====================================');
  print('');
  print('Generated Files:');
  print('- test_results/latest_summary.md');
  print('- test_results/audit_history.jsonl');
  print('- test_results/metrics.csv');
  print('- test_results/regression_alerts.md');
  print('');
}
