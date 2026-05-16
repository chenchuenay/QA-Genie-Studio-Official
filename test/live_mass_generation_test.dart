// Live Groq stress run — one API call per scenario, no retries.
//
// Run:
//   flutter test test/live_mass_generation_test.dart \
//     --dart-define=AI_PROVIDER=groq \
//     --dart-define=LIVE_AI=1
//
// Optional:
//   --dart-define=QA_GENIE_PERF_STRICT=1   — fail if Core > 8s or Pro > 15s
//   --dart-define=QA_GENIE_TEST=1          — temp dirs use system temp (exports)
//
// Flutter's `TestWidgetsFlutterBinding` mocks `HttpClient` (tests see HTTP 400) unless we
// inject a passthrough factory — required for live Groq generations.

import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/domain/usecases/export_validation_service.dart';
import 'package:qa_genie/engine/generation_metrics.dart';
import 'package:qa_genie/engine/generation_result.dart';
import 'package:qa_genie/engine/generation_service.dart';
import 'package:qa_genie/engine/platform_rules.dart';
import 'package:qa_genie/engine/qa_heuristics_engine.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';

import 'support/live_http.dart';

const _liveAi = String.fromEnvironment('LIVE_AI') == '1';
const _aiProvider = String.fromEnvironment('AI_PROVIDER', defaultValue: 'gemini');
const _perfStrict = String.fromEnvironment('QA_GENIE_PERF_STRICT') == '1';

/// Core (10) vs Pro (20) matches [GenerationService] `targetCount` rule.
int _expectedCaseCount(int maxCases) => maxCases > 10 ? 20 : 10;

/// Mirrors production intent dedup key (see `GenerationService._intentSignature`).
String _intentSignature(TestCaseModel tc) {
  final normalizedTitle = tc.title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  final firstAction = tc.steps.isNotEmpty
      ? tc.steps.first.action
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .trim()
      : '';

  final expected = tc.expectedResult
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  return '$normalizedTitle|$firstAction|$expected';
}

const _bannedPhrases = <String>[
  'works correctly',
  'works as expected',
  'behaves as expected',
  'successful operation',
  'operation successful',
  'verify success',
  'application responds correctly',
  'maintains stable behavior',
  'dummy data',
  'password123',
  'user@example.com',
  'test@example.com',
  'placeholder',
  'lorem ipsum',
  'numeric input',
  'workflow stability',
  'default workflow stability',
];

const _allowedTypesUpper = <String>{
  'POSITIVE',
  'NEGATIVE',
  'SECURITY',
  'EDGE',
  'VALIDATION',
  'SESSION',
  'USABILITY',
  'NETWORK',
  'GENERAL',
  'FUNCTIONAL',
};

class _Scenario {
  const _Scenario(this.module, this.feature, this.platform, {this.notes});

  final String module;
  final String feature;
  final String platform;
  final String? notes;
}

/// 24 diverse intents × Core + Pro = 48 single-call generations.
const _scenarios = <_Scenario>[
  _Scenario('Authentication', 'user login with email', 'Web'),
  _Scenario('Payments', 'checkout with saved card', 'Web'),
  _Scenario('Cart', 'apply promotional coupon', 'Web'),
  _Scenario('Search', 'typeahead product search', 'Web'),
  _Scenario('Profile', 'update contact phone number', 'Web'),
  _Scenario('Registration', 'email verification link', 'Web'),
  _Scenario('Orders', 'cancel pending order', 'Web'),
  _Scenario('Notifications', 'mark alert as read', 'Web'),
  _Scenario('Security', 'password reset request', 'Web'),
  _Scenario('Accessibility', 'keyboard focus order', 'Web'),
  _Scenario('MobileAuth', 'biometric unlock', 'Mobile'),
  _Scenario('MobileCommerce', 'add item to cart', 'Mobile'),
  _Scenario('MobileProfile', 'upload avatar image', 'Mobile'),
  _Scenario('MobileSession', 'restore state after backgrounding', 'Mobile'),
  _Scenario('MobileNetwork', 'offline queue retry', 'Mobile'),
  _Scenario('ApiAuth', 'issue session token', 'API'),
  _Scenario('ApiOrders', 'create order resource', 'API'),
  _Scenario('ApiPayments', 'process refund webhook', 'API'),
  _Scenario('ApiValidation', 'reject malformed JSON body', 'API'),
  _Scenario('ApiRateLimit', 'throttle burst traffic', 'API'),
  _Scenario('Otp', 'verify one-time passcode', 'Web', notes: 'Use reserved test phone numbers only.'),
  _Scenario('Subscription', 'upgrade billing plan', 'Web'),
  _Scenario('Inventory', 'low stock alert threshold', 'Web'),
  _Scenario('Admin', 'role permission change', 'Web'),
];

void _printRunHeader(
  _Scenario s,
  int maxCases,
  Stopwatch sw,
  GenerationMetrics metrics,
  GenerationResult result,
) {
  // ignore: avoid_print
  print('\n'
      '══ ${s.module} / ${s.feature} / ${s.platform} '
      '(maxCases=$maxCases → expect ${_expectedCaseCount(maxCases)}) '
      '═ ${sw.elapsedMilliseconds}ms');
  // ignore: avoid_print
  print('  warning: ${result.warning ?? 'none'}');
  // ignore: avoid_print
  print('  metrics: $metrics');
  // ignore: avoid_print
  print('  parser salvage: recovered=${PipelineDebugStore.recoveredObjectCount} '
      'rejectedChunks=${PipelineDebugStore.rejectedObjectCount} '
      'malformedSkipped=${PipelineDebugStore.malformedObjectsSkipped} '
      'partialRecovery=${PipelineDebugStore.partialRecoveryUsed} '
      'cleanerRepairs=${PipelineDebugStore.cleanerRepairCount}');
}

void _assertProductionQuality(
  List<TestCaseModel> cases,
  _Scenario scenario,
  int expectedCount,
) {
  expect(cases, hasLength(expectedCount),
      reason: '${scenario.module}/${scenario.feature} count mismatch');

  final titles = cases.map((c) => c.title.trim().toLowerCase()).toList();
  expect(titles.toSet(), hasLength(titles.length),
      reason: 'duplicate titles in suite');

  final intents = cases.map(_intentSignature).toList();
  expect(intents.toSet(), hasLength(intents.length),
      reason: 'duplicate intent signatures in suite');

  for (final tc in cases) {
    expect(tc.id, isNotEmpty);
    expect(tc.actualResult, isEmpty);
    expect(tc.status, 'Not Executed');
    expect(tc.steps.length, greaterThanOrEqualTo(3),
        reason: tc.title);
    expect(tc.expectedResult.trim(), isNotEmpty, reason: tc.title);
    expect(tc.expectedResult.length, greaterThan(40), reason: tc.title);
    expect(
      QaHeuristicsEngine.hasWeakExpectedResult(tc.expectedResult),
      isFalse,
      reason: 'weak final expected: ${tc.title}',
    );

    final typeUp = tc.type.trim().toUpperCase();
    expect(_allowedTypesUpper.contains(typeUp), isTrue,
        reason: 'invalid type "$typeUp" for ${tc.title}');

    expect(['High', 'Medium', 'Low'].contains(tc.priority), isTrue,
        reason: 'invalid priority ${tc.priority}');

    final combined =
        '${tc.title} ${tc.expectedResult} ${tc.preconditions.join(' ')} '
            '${tc.steps.map((s) => '${s.action} ${s.data} ${s.expected}').join(' ')}'
            .toLowerCase();

    expect(
      PlatformRules.violatesPlatform(scenario.platform, combined),
      isFalse,
      reason: 'platform vocabulary leak: ${tc.title}',
    );

    for (final phrase in _bannedPhrases) {
      expect(combined, isNot(contains(phrase)),
          reason: '$phrase — ${tc.title}');
    }

    final stepSigs = tc.steps
        .map((s) =>
            '${s.action.trim()}|${s.data.trim()}|${s.expected.trim()}')
        .toList();
    expect(stepSigs.toSet(), hasLength(stepSigs.length),
        reason: 'repeated identical steps: ${tc.title}');

    for (final step in tc.steps) {
      expect(step.action.trim().length, greaterThan(8), reason: tc.title);
      expect(step.expected.trim().length, greaterThanOrEqualTo(35), reason: tc.title);
      expect(
        QaHeuristicsEngine.hasWeakExpectedResult(step.expected),
        isFalse,
        reason: 'weak step expected: ${tc.title}',
      );
    }
  }
}

Future<void> _stressExportStructures(
  List<TestCaseModel> cases,
  _Scenario scenario,
) async {
  final validation = ExportValidationService.validate(cases);
  expect(validation.isValid, isTrue,
      reason: validation.errors.join('\n'));

  final excel = Excel.createExcel();
  final sheet = excel['Test Cases'];
  for (final row in ExportMapper.toExcel(
    cases,
    moduleName: scenario.module,
    featureName: scenario.feature,
  )) {
    sheet.appendRow(row.map(TextCellValue.new).toList());
  }
  final xlsx = excel.save();
  expect(xlsx, isNotNull);
  expect(xlsx!.length, greaterThan(512));

  final jiraCsv = ExportMapper.toJira(
    cases,
    featureName: scenario.feature,
  );
  expect(jiraCsv.length, greaterThanOrEqualTo(cases.length + 1));

  final xray = ExportMapper.toXray(
    cases,
    moduleName: scenario.module,
    featureName: scenario.feature,
  );
  expect(xray.length, cases.length);
  final xrayEncoded = jsonEncode(xray);
  expect(xrayEncoded.isNotEmpty, isTrue);

  final pdfRows = ExportMapper.toPdf(cases.map((e) => e.copy()).toList());
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        pw.Table.fromTextArray(
          headers: const [
            'ID',
            'Title',
            'Preconditions',
            'Steps',
            'Test Data',
            'Expected Result',
            'Priority',
          ],
          data: pdfRows
              .map(
                (row) => [
                  (row['ID'] ?? '').toString(),
                  (row['Title'] ?? '').toString(),
                  (row['Preconditions'] ?? '').toString(),
                  (row['Steps'] ?? '').toString(),
                  (row['Test Data'] ?? '').toString(),
                  (row['Expected Result'] ?? '').toString(),
                  (row['Priority'] ?? '').toString(),
                ],
              )
              .toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
          ),
          cellStyle: const pw.TextStyle(fontSize: 6),
        ),
      ],
    ),
  );

  final pdfBytes = await pdf.save();
  expect(pdfBytes.isNotEmpty, isTrue);
}

void main() {
  ensureLiveGroqNetworking();

  final skipMessage = !_liveAi
      ? 'Set LIVE_AI=1 for live Groq runs.'
      : (_aiProvider != 'groq'
          ? 'Set AI_PROVIDER=groq for this mass suite.'
          : false);

  test(
    'mass Groq: matrix (Core + Pro) + exports + salvage metrics',
    () async {
      final service = GenerationService();
      final failures = <String>[];

      for (final tier in const [10, 20]) {
        for (final scenario in _scenarios) {
          final sw = Stopwatch()..start();
          GenerationResult result;
          try {
            result = await service.execute(
              module: scenario.module,
              feature: scenario.feature,
              platform: scenario.platform,
              maxCases: tier,
              notes: scenario.notes,
            );
          } catch (e, st) {
            failures.add('${scenario.module}/${scenario.feature} '
                'tier=$tier THROW $e\n$st');
            continue;
          }
          sw.stop();

          final expected = _expectedCaseCount(tier);
          final cases = result.cases;

          _printRunHeader(scenario, tier, sw, GenerationService.lastMetrics, result);

          expect(GenerationService.lastMetrics.aiCalls, 1,
              reason: 'single-call invariant');

          if (_perfStrict) {
            final budgetMs = tier > 10 ? 15000 : 8000;
            expect(
              sw.elapsedMilliseconds,
              lessThan(budgetMs),
              reason:
                  '${scenario.module} exceeded ${budgetMs}ms (tier=$tier)',
            );
          }

          try {
            _assertProductionQuality(cases, scenario, expected);
            await _stressExportStructures(cases, scenario);
          } catch (e) {
            failures.add('${scenario.module}/${scenario.feature} '
                'tier=$tier QUALITY/EXPORT $e');
          }
        }
      }

      expect(
        failures,
        isEmpty,
        reason: failures.join('\n---\n'),
      );
    },
    skip: skipMessage,
    timeout: const Timeout(Duration(minutes: 60)),
  );
}
