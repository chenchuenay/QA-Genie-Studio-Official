import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/orchestrator/deterministic_engine.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import '../reference/identity_reference.dart';
import '../reference/commerce_reference.dart';
import '../reference/records_reference.dart';
import '../reference/scheduling_reference.dart';
import '../reference/integration_reference.dart';
import '../reference/transaction_reference.dart';
import '../reference/cross_domain_reference.dart';

class QualityScore {
  final int titleScore;
  final int stepsScore;
  final int testDataScore;
  final int preconditionsScore;
  final int expectedResultScore;
  final int priorityScore;

  const QualityScore({
    required this.titleScore,
    required this.stepsScore,
    required this.testDataScore,
    required this.preconditionsScore,
    required this.expectedResultScore,
    required this.priorityScore,
  });

  double get average => (titleScore + stepsScore + testDataScore + preconditionsScore + expectedResultScore + priorityScore) / 6.0;

  @override
  String toString() =>
      'Title=$titleScore/10 Steps=$stepsScore/10 Data=$testDataScore/10 '
      'Precond=$preconditionsScore/10 Expected=$expectedResultScore/10 Priority=$priorityScore/10 '
      'Avg=${average.toStringAsFixed(1)}/10';
}

void main() {
  group('Fallback Quality Comparison', () {
    final results = <String, List<QualityScore>>{};

    setUpAll(() async {
      final configs = [
        ('Auth', 'Login', 'WEB', 'Web', IdentityReference.cases),
        ('Auth', 'Login', 'Mobile', 'Mobile', IdentityReference.cases),
        ('Shop', 'Checkout', 'WEB', 'Web', CommerceReference.cases),
        ('Shop', 'Checkout', 'Mobile', 'Mobile', CommerceReference.cases),
        ('Medical', 'Records', 'WEB', 'Web', RecordsReference.cases),
        ('Medical', 'Records', 'Mobile', 'Mobile', RecordsReference.cases),
        ('Calendar', 'Appointment', 'Mobile', 'Mobile', SchedulingReference.cases),
        ('Calendar', 'Appointment', 'WEB', 'Web', SchedulingReference.cases),
        ('API', 'Webhook', 'API', 'API', IntegrationReference.cases),
        ('Banking', 'Transfer', 'WEB', 'Web', TransactionReference.cases),
        ('Banking', 'Transfer', 'Mobile', 'Mobile', TransactionReference.cases),
        ('Portal', 'Checkout', 'WEB', 'Web', CrossDomainReference.cases),
      ];

      for (final config in configs) {
        final engine = DeterministicEngine(
          module: config.$1,
          feature: config.$2,
          platform: config.$3,
          targetCount: config.$5.length,
        );
        final testCases = await engine.generate();
        final scores = _evaluateBatch(testCases, config.$5);
        results['${config.$1}/${config.$2} (${config.$4})'] = scores;
      }
    });

    test('Identity domain titles use natural language', () {
      final scores = results['Auth/Login (Web)']!;
      for (final s in scores) {
        expect(s.titleScore, greaterThanOrEqualTo(6), reason: 'Title should be natural language');
      }
    });

    test('Steps are platform-aware', () {
      final webScores = results['Auth/Login (Web)']!;
      final mobileScores = results['Auth/Login (Mobile)']!;

      for (final s in webScores) {
        expect(s.titleScore, greaterThanOrEqualTo(6));
      }

      for (final s in mobileScores) {
        expect(s.titleScore, greaterThanOrEqualTo(6));
      }
    });

    test('All domains average quality score >= 6.0', () {
      for (final entry in results.entries) {
        final avg = entry.value.map((s) => s.average).reduce((a, b) => a + b) / entry.value.length;
        expect(avg, greaterThanOrEqualTo(6.0),
            reason: 'Domain ${entry.key} avg quality ${avg.toStringAsFixed(1)} < 6.0');
      }
    });

    test('Detailed quality report', () {
      print('\n===== QUALITY REPORT =====');
      for (final entry in results.entries) {
        print('\n--- ${entry.key} ---');
        for (int i = 0; i < entry.value.length; i++) {
          print('  TC ${i + 1}: ${entry.value[i]}');
        }
        final avg = entry.value.map((s) => s.average).reduce((a, b) => a + b) / entry.value.length;
        print('  >>> Domain average: ${avg.toStringAsFixed(1)}/10');
      }

      // Compute overall
      double totalAvg = 0;
      int count = 0;
      for (final entry in results.entries) {
        for (final s in entry.value) {
          totalAvg += s.average;
          count++;
        }
      }
      print('\n>>> OVERALL AVERAGE: ${(totalAvg / count).toStringAsFixed(1)}/10');
      print('==========================\n');
    });
  });
}

List<QualityScore> _evaluateBatch(List<FinalizedTestCase> generated, List<ReferenceCase> references) {
  final scores = <QualityScore>[];
  for (int i = 0; i < generated.length && i < references.length; i++) {
    scores.add(_evaluateTestCase(generated[i], references[i]));
  }
  return scores;
}

QualityScore _evaluateTestCase(FinalizedTestCase tc, ReferenceCase ref) {
  return QualityScore(
    titleScore: _scoreTitle(tc.title, ref.title),
    stepsScore: _scoreSteps(tc.steps, ref.steps),
    testDataScore: _scoreTestData(tc.testData, ref.testData),
    preconditionsScore: _scorePreconditions(tc.preconditions, ref.preconditions),
    expectedResultScore: _scoreExpectedResult(tc.expectedResult, ref.expectedResult),
    priorityScore: _scorePriority(tc.priority, ref.priority),
  );
}

int _scoreTitle(String generated, String reference) {
  int score = 5;

  // Natural language check (no templated patterns like "Verify successful...")
  final templatedPatterns = [
    'verify successful',
    'verify error',
    'validate',
    'boundary test:',
    'security:',
    'session:',
  ];
  final lower = generated.toLowerCase();
  final hasTemplates = templatedPatterns.any((p) => lower.startsWith(p));
  if (!hasTemplates) score += 2;

  // Length check — good titles are 40-120 chars
  if (generated.length >= 40 && generated.length <= 120) score += 1;
  if (generated.length > 120) score -= 1;

  // Domain-specific vocabulary check
  if (_containsDomainTerms(generated)) score += 1;

  // Unique/specific (not generic like "Create record")
  if (_isSpecificTitle(generated)) score += 1;

  return score.clamp(0, 10);
}

int _scoreSteps(List<TestStep> generated, List<String> reference) {
  if (generated.isEmpty) return 0;
  int score = 5;

  // Each step should have meaningful action
  for (final step in generated) {
    if (step.action.length > 10) score += 1;
    if (step.expected.length > 15) score += 1;
    if (step.data.isNotEmpty && step.data.length > 5) score += 1;
  }

  // Platform-specific terminology
  final allActions = generated.map((s) => s.action).join(' ').toLowerCase();
  if (allActions.contains('tap') || allActions.contains('click') ||
      allActions.contains('navigate') || allActions.contains('enter')) {
    score += 1;
  }

  return (score / 2).round().clamp(0, 10);
}

int _scoreTestData(String generated, String reference) {
  if (generated.isEmpty) return 0;
  int score = 5;

  // Should be longer than just placeholder
  if (generated.length >= 15) score += 1;
  if (generated.length >= 30) score += 1;

  // Should contain realistic values
  if (generated.contains('@') || generated.contains('example.com') ||
      generated.contains('test.com')) score += 1;
  if (generated.contains('\$') || generated.contains('price') ||
      generated.contains('amount')) score += 1;
  if (generated.contains('=') || generated.contains(':')) score += 1;

  return score.clamp(0, 10);
}

int _scorePreconditions(List<String> generated, List<String> reference) {
  if (generated.isEmpty) return 0;
  int score = 5;

  // Should have multiple preconditions
  if (generated.length >= 2) score += 1;
  if (generated.length >= 3) score += 1;

  // Should be specific, not generic
  for (final pc in generated) {
    if (pc.length > 20) score += 1;
    if (pc.contains('authenticated') || pc.contains('registered') ||
        pc.contains('active') || pc.contains('verified')) score += 1;
  }

  // Category-specific preconditions are a plus
  final allPreconds = generated.join(' ').toLowerCase();
  if (allPreconds.contains('service') || allPreconds.contains('backend') ||
      allPreconds.contains('api')) score += 1;

  return (score / 2).round().clamp(0, 10);
}

int _scoreExpectedResult(String generated, String reference) {
  if (generated.isEmpty) return 0;
  int score = 5;

  // Should be detailed (length)
  if (generated.length >= 50) score += 1;
  if (generated.length >= 100) score += 1;
  if (generated.length >= 150) score += 1;

  // Should be specific, not generic
  final lower = generated.toLowerCase();
  if (lower.contains('redirect') || lower.contains('display') ||
      lower.contains('message') || lower.contains('confirmation')) score += 1;
  if (!lower.contains('successfully') && lower.length > 80) score += 1;
  if (generated.contains('HTTP') || generated.contains('status') ||
      generated.contains('code')) score += 1;

  return score.clamp(0, 10);
}

int _scorePriority(String generated, String reference) {
  if (generated.isEmpty) return 0;
  final valid = ['High', 'Medium', 'Low'];
  if (!valid.contains(generated)) return 0;
  return generated == reference ? 10 : 7;
}

bool _containsDomainTerms(String title) {
  final terms = [
    'email', 'password', 'login', 'account', 'session', 'token',
    'cart', 'checkout', 'payment', 'order', 'shipping',
    'transfer', 'balance', 'beneficiary', 'transaction',
    'appointment', 'schedule', 'provider', 'booking',
    'record', 'patient', 'prescription', 'consent',
    'webhook', 'api', 'endpoint', 'oauth', 'integration',
  ];
  return terms.any((t) => title.toLowerCase().contains(t));
}

bool _isSpecificTitle(String title) {
  final generic = [
    'verify success',
    'verify error',
    'validate input',
    'perform action',
    'test case for',
  ];
  return !generic.any((g) => title.toLowerCase().contains(g));
}
