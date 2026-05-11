import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:qa_app/engine/generation_service.dart';
import 'package:qa_app/data/models/test_case_model.dart';

const Map<String, int> weights = {
  'atomic': 1, 'actionable': 2, 'preconds': 2, 'sequential': 3,
  'observable': 3, 'realistic': 2, 'nogeneric': 2, 'risk': 3,
  'independent': 1, 'rhythm': 1, 'feasible': 3,
};
int maxScore = weights.values.reduce((a, b) => a + b);

const _bannedPhrases = [
  'properly', 'correctly', 'successfully', 'appropriately',
  'as expected', 'works fine', 'should', 'might', 'maybe',
  'can be', 'could be'
];
const _vagueVerbs = ['check', 'test', 'verify feature', 'validate'];

bool _hasAnd(String t) =>
    t.contains(' and ') || t.contains(' while ') || t.contains(' & ');
int _scoreAtom(String t) => _hasAnd(t.toLowerCase()) ? 0 : 1;
int _scoreActionable(String t) {
  final x = t.toLowerCase();
  if (_vagueVerbs.any((v) => x.startsWith(v))) return 0;
  return (x.startsWith('verify ') && x.length > 30) ? 1 : 0;
}
int _scorePreconds(List<String> p) {
  if (p.isEmpty) return 0;
  final c = p.join(' ').toLowerCase();
  if (c.contains('user is on') || c.contains('app is running')) return 0;
  return p.any((e) => e.trim().length > 15) ? 1 : 0;
}
int _scoreSequential(List<TestStep> steps) {
  if (steps.length < 2) return 0;
  final acts = steps.map((s) => s.action.toLowerCase()).toList();
  bool seenNav = false, seenAction = false;
  for (final a in acts) {
    if (a.contains('open') || a.contains('navigate') || a.contains('launch')) {
      if (seenAction) return 0;
      seenNav = true;
    } else if (a.contains('enter') || a.contains('type') || a.contains('fill')) {
      if (!seenNav) return 0;
      seenAction = true;
    } else if (a.contains('verify') || a.contains('check')) {
      if (!seenAction) return 0;
    }
  }
  return 1;
}
int _scoreObservable(String e) {
  final x = e.toLowerCase();
  const indicators = [
    'is displayed', 'appears', 'redirected', 'visible',
    'created', 'updated', 'blocked', 'rejected',
    'shows', 'becomes', 'transitions', 'stays', 'remains'
  ];
  if (!indicators.any((i) => x.contains(i))) return 0;
  if (_bannedPhrases.any((p) => x.contains(p))) return 0;
  return x.length > 30 ? 1 : 0;
}
int _scoreRealistic(List<TestStep> steps) {
  final d = steps.map((s) => s.data).where((x) => x.isNotEmpty).join(' ');
  if (d.isEmpty) return 0;
  if (d.contains('test@') || d.contains('example') || d.contains('dummy')) return 0;
  return (d.contains('@') || d.length > 20 || d.contains('token') || d.contains('payload')) ? 1 : 0;
}
int _scoreNoGeneric(String t) =>
    _bannedPhrases.any((p) => t.toLowerCase().contains(p)) ? 0 : 1;
int _scoreRisk(String title, List<TestStep> steps) {
  final f = '$title ${steps.map((s) => s.action).join(' ')}'.toLowerCase();
  final concepts = {
    'timeout': 'Verify.*timeout',
    'session expiry': 'Verify.*session.*expir',
    'invalid token': 'Verify.*invalid.*token',
    'sql injection': 'Verify.*sql',
    'xss': 'Verify.*xss',
    'rate limit': 'Verify.*rate.*limit',
    'offline': 'Verify.*offline',
    'concurrent': 'Verify.*concurrent',
  };
  for (final k in concepts.keys) {
    if (f.contains(k) &&
        steps.any((s) =>
            RegExp(concepts[k]!, caseSensitive: false).hasMatch(s.action))) {
      return 1;
    }
  }
  if (steps.any((s) =>
      s.action.toLowerCase().contains('inject') ||
      s.action.toLowerCase().contains('bypass'))) return 1;
  return 0;
}
int _scoreIndependent(List<String> p) =>
    p.join(' ').toLowerCase().contains('previous test') ? 0 : 1;
int _scoreRhythm(List<TestStep> steps) {
  if (steps.length < 3) return 0;
  return steps
          .map((s) => s.action.split(' ').first.toLowerCase())
          .toSet()
          .length >=
      2
      ? 1
      : 0;
}
int _scoreFeasible(String platform, List<TestStep> steps) {
  return steps.every((s) {
    final a = s.action.toLowerCase();
    if (platform == 'Web' && (a.contains('swipe') || a.contains('tap'))) return false;
    if (platform == 'Mobile' && (a.contains('right click') || a.contains('hover'))) return false;
    if (platform == 'API' && (a.contains('click') || a.contains('tap'))) return false;
    return true;
  }) ? 1 : 0;
}

String _fingerprint(TestCaseModel tc) {
  final acts = tc.steps.map((s) => s.action.toLowerCase().trim()).toList();
  acts.sort();
  return '${tc.title.toLowerCase().trim()}|${acts.join(';')}';
}

bool _contradiction(TestCaseModel tc) {
  final t = tc.title.toLowerCase();
  final e = tc.expectedResult.toLowerCase();
  if (RegExp(r'invalid|reject|block|denied|fail|wrong|empty|malformed').hasMatch(t)) {
    if (RegExp(r'is displayed|appears|redirected|success|created|updated').hasMatch(e)) {
      if (!RegExp(r'not|prevent|denied|rejected|blocked|reset|cleared|invalid|error|message').hasMatch(e)) {
        return true;
      }
    }
  }
  return false;
}

bool _suiteCoverage(List<TestCaseModel> cases) {
  final cats = cases.map((c) => c.type.toUpperCase()).toSet();
  return {
    'POSITIVE', 'NEGATIVE', 'EDGE', 'SECURITY',
    'VALIDATION', 'SESSION', 'USABILITY'
  }.intersection(cats).length >= 4;
}

Map<String, int> scoreDetailed(TestCaseModel tc, String platform) {
  return {
    'atomic': _scoreAtom(tc.title),
    'actionable': _scoreActionable(tc.title),
    'preconds': _scorePreconds(tc.preconditions),
    'sequential': _scoreSequential(tc.steps),
    'observable': _scoreObservable(tc.expectedResult),
    'realistic': _scoreRealistic(tc.steps),
    'nogeneric': _scoreNoGeneric(tc.title + ' ' + tc.expectedResult),
    'risk': _scoreRisk(tc.title, tc.steps),
    'independent': _scoreIndependent(tc.preconditions),
    'rhythm': _scoreRhythm(tc.steps),
    'feasible': _scoreFeasible(platform, tc.steps),
  };
}

int weightedScore(Map<String, int> dims) {
  return dims.entries.fold(0, (sum, e) => sum + e.value * (weights[e.key] ?? 1));
}

void main() async {
  final service = GenerationService();
  final platforms = ['Web', 'Mobile', 'API'];
  final modes = {10: 'Core', 20: 'Pro'};
  final now = DateTime.now().toIso8601String().substring(0, 19);

  final logFile = File('test_results/quality_trend.csv');
  if (!logFile.parent.existsSync()) logFile.parent.createSync(recursive: true);
  if (!logFile.existsSync() || logFile.lengthSync() == 0) {
    logFile.writeAsStringSync(
      'timestamp,platform,mode,requested,delivered,avg_weighted_score,min,max,above_half,'
      'atom,action,prec,seq,obs,data,nogen,risk,ind,rhythm,feas,coverage_ok,dup_count,contradiction_count\n',
    );
  }

  final reportBuf = StringBuffer();
  reportBuf.writeln('=== QA GENIE QUALITY REPORT ===');
  reportBuf.writeln('Generated: $now');
  reportBuf.writeln('');

  final allCasesJson = <Map<String, dynamic>>[];

  for (final platform in platforms) {
    for (final count in modes.keys) {
      final mode = modes[count]!;
      reportBuf.writeln('----- $platform · $mode ($count cases) -----');
      final result = await service.execute(
        module: 'User Authentication',
        feature: 'Login',
        platform: platform,
        maxCases: count,
      );
      final cases = result.cases;

      final fingerprints = <String>{};
      int duplicates = 0, contradictions = 0;
      final dimSums = <String, int>{};
      final allScores = <int>[];

      for (final tc in cases) {
        final dims = scoreDetailed(tc, platform);
        final fp = _fingerprint(tc);
        if (fingerprints.contains(fp)) {
          duplicates++;
        } else {
          fingerprints.add(fp);
        }
        if (_contradiction(tc)) contradictions++;
        dims.forEach((k, v) {
          dimSums[k] = (dimSums[k] ?? 0) + v;
        });
        final ws = weightedScore(dims);
        allScores.add(ws);
        allCasesJson.add({
          'platform': platform,
          'mode': mode,
          'id': tc.id,
          'title': tc.title,
          'preconditions': tc.preconditions,
          'steps': tc.steps.map((s) => s.toJson()).toList(),
          'expectedResult': tc.expectedResult,
          'priority': tc.priority,
          'type': tc.type,
          'weighted_score': ws,
          'dimensions': dims,
        });
      }

      final n = cases.length;
      final avg = n == 0 ? 0.0 : allScores.reduce((a, b) => a + b) / n;
      final minS = n == 0 ? 0 : allScores.reduce(min);
      final maxS = n == 0 ? 0 : allScores.reduce(max);
      final aboveHalf = allScores.where((s) => s >= maxScore / 2).length;
      final coverageOk = _suiteCoverage(cases);

      final csvLine = StringBuffer();
      csvLine.write('$now,$platform,$mode,$count,$n,${avg.toStringAsFixed(1)},$minS,$maxS,$aboveHalf,');
      csvLine.write('${dimSums['atomic'] ?? 0},${dimSums['actionable'] ?? 0},${dimSums['preconds'] ?? 0},');
      csvLine.write('${dimSums['sequential'] ?? 0},${dimSums['observable'] ?? 0},${dimSums['realistic'] ?? 0},');
      csvLine.write('${dimSums['nogeneric'] ?? 0},${dimSums['risk'] ?? 0},${dimSums['independent'] ?? 0},');
      csvLine.write('${dimSums['rhythm'] ?? 0},${dimSums['feasible'] ?? 0},${coverageOk ? 1 : 0},$duplicates,$contradictions\n');
      await logFile.writeAsString(csvLine.toString(), mode: FileMode.append);

      reportBuf.writeln('  Requested: $count | Delivered: $n');
      reportBuf.writeln('  Avg Weighted Score: ${avg.toStringAsFixed(1)} / $maxScore');
      reportBuf.writeln('  Min: $minS | Max: $maxS | ≥${(maxScore / 2).round()}: $aboveHalf/$n');
      reportBuf.writeln('  Duplicates: $duplicates | Contradictions: $contradictions');
      reportBuf.writeln('  Coverage: ${coverageOk ? 'OK' : 'LOW'}');
      reportBuf.writeln('  Dimension scores (sum):');
      for (final d in [
        'atomic', 'actionable', 'preconds', 'sequential',
        'observable', 'realistic', 'nogeneric', 'risk',
        'independent', 'rhythm', 'feasible'
      ]) {
        final sum = dimSums[d] ?? 0;
        final pct = n > 0 ? (sum / n * 100).toStringAsFixed(0) + '%' : '0%';
        reportBuf.writeln('    $d: $sum/$n ($pct)');
      }
      reportBuf.writeln('');
    }
  }

  final reportFile = File('test_results/quality_report.txt');
  await reportFile.writeAsString(reportBuf.toString());
  print(reportBuf.toString());

  final jsonFile = File('test_results/last_generated_cases.json');
  await jsonFile.writeAsString(const JsonEncoder.withIndent('  ').convert(allCasesJson));

  print('Report saved: ${reportFile.path}');
  print('Cases JSON: ${jsonFile.path}');
  print('Trend CSV: ${logFile.path}');
}
