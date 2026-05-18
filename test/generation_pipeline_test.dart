import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/generation_mode.dart';
import 'package:qa_genie/engine/scenario_planner.dart';
import 'package:qa_genie/core/network/response_parser.dart';
import 'package:qa_genie/core/network/response_cleaner.dart';
import 'package:qa_genie/engine/fallback/fallback_generator.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';
import 'package:qa_genie/core/error/ui_error_service.dart';
import 'package:qa_genie/core/logging/telemetry_collector.dart';
import 'package:qa_genie/core/error/ui_error_store.dart';

void main() {
  setUp(() {
    TelemetryCollector().clear();
    UiErrorStore().clear();
  });

  test('parser repairs JavaScript repeat strings without another API call', () {
    final raw = jsonEncode([
      {
        'title': 'Verify email field handles maximum character length',
        'module': 'login',
        'feature': 'user login',
        'platform': 'Web',
        'priority': 'High',
        'type': 'EDGE',
        'preconditions': ['The login page is open.'],
        'steps': [
          {
            'action': 'Paste a long email value into the email field',
            'data': 'placeholder',
            'expected':
                'The email field displays a visible length validation message.',
          },
          {
            'action': 'Enter a valid password',
            'data': 'S3curePass!482',
            'expected':
                'The password field accepts the value and remains masked.',
          },
          {
            'action': 'Click the sign in button',
            'data': '',
            'expected':
                'The form prevents authentication while the email remains invalid.',
          },
        ],
        'expectedResult':
            'The login form enforces the email length limit and keeps the user on the login page without creating an authenticated session.',
      },
    ]).replaceFirst('"placeholder"', '"a".repeat(64)');

    final cleaned = ResponseCleaner.clean(raw, 'groq');
    final parsed = ResponseParser.parseArray(cleaned);

    expect(parsed, hasLength(1));
    expect(parsed.single.steps.first.data, hasLength(64));
  });

  test('parser repairs simple JavaScript replace plus string expressions', () {
    final raw = jsonEncode([
      {
        'title': 'Verify email field handles maximum character length',
        'module': 'login',
        'feature': 'user login',
        'platform': 'Web',
        'priority': 'High',
        'type': 'EDGE',
        'preconditions': ['The login page is open.'],
        'steps': [
          {
            'action': 'Paste a generated email value into the email field',
            'data': 'placeholder',
            'expected':
                'The email field displays a visible validation state for the entered value.',
          },
          {
            'action': 'Enter a valid password',
            'data': 'S3curePass!482',
            'expected':
                'The password field accepts the value and remains masked.',
          },
          {
            'action': 'Click the sign in button',
            'data': '',
            'expected':
                'The form prevents authentication while the email remains invalid.',
          },
        ],
        'expectedResult':
            'The login form handles the generated email string as literal data and keeps the user on the login page without creating an authenticated session.',
      },
    ]).replaceFirst('"placeholder"', '"a".replace("a", "qa_long_email") + "@example.test"');

    final cleaned = ResponseCleaner.clean(raw, 'groq');
    final parsed = ResponseParser.parseArray(cleaned);

    expect(parsed, hasLength(1));
    expect(parsed.single.steps.first.data, 'qa_long_email@example.test');
  });

  test('parser repairs adjacent string concatenation expressions', () {
    final raw = jsonEncode([
      {
        'title': 'Verify email field handles maximum character length',
        'module': 'login',
        'feature': 'user login',
        'platform': 'Web',
        'priority': 'High',
        'type': 'EDGE',
        'preconditions': ['The login page is open.'],
        'steps': [
          {
            'action': 'Paste a long email value into the email field',
            'data': 'placeholder',
            'expected':
                'The email field displays a visible validation state for the entered value.',
          },
          {
            'action': 'Enter a valid password',
            'data': 'S3curePass!482',
            'expected':
                'The password field accepts the value and remains masked.',
          },
          {
            'action': 'Click the sign in button',
            'data': '',
            'expected':
                'The form prevents authentication while the email remains invalid.',
          },
        ],
        'expectedResult':
            'The login form handles the concatenated email string as literal data and keeps the user on the login page without creating an authenticated session.',
      },
    ]).replaceFirst('"placeholder"', '"qa_long_email" + "@example.test"');

    final cleaned = ResponseCleaner.clean(raw, 'groq');
    final parsed = ResponseParser.parseArray(cleaned);

    expect(parsed, hasLength(1));
    expect(parsed.single.steps.first.data, 'qa_long_email@example.test');
  });

  test('UI forensic error capture validation', () async {
    final collector = TelemetryCollector();
    final store = UiErrorStore();
    store.startOperation('test_op_123');

    // Trigger test errors
    UiErrorService.logOnly(
      source: ErrorSource.network,
      screen: 'ForensicTest',
      stage: ErrorStage.aiCall,
      severity: ErrorSeverity.critical,
      userMessage: 'Intentional network timeout',
      error: 'TimeoutException: Connection lost',
    );

    UiErrorService.logOnly(
      source: ErrorSource.uiPreview,
      screen: 'ForensicTest',
      stage: ErrorStage.uiRender,
      severity: ErrorSeverity.error,
      userMessage: 'Intentional UI render error',
      error: 'RenderException: Null widget',
    );

    // Freeze telemetry snapshot
    final snapshot = collector.freeze();

    // Verification
    expect(snapshot.uiErrorTraces.length, 2);
    
    final trace1 = snapshot.uiErrorTraces[0];
    expect(trace1.userMessage, 'Intentional network timeout');
    expect(trace1.technicalError, contains('TimeoutException'));

    final trace2 = snapshot.uiErrorTraces[1];
    expect(trace2.userMessage, 'Intentional UI render error');
    expect(trace2.technicalError, contains('RenderException'));
  });

  test('login fallback generates canonical export-safe cases', () {
    final cases = FallbackGenerator.generate(
      count: 20,
      module: 'login',
      feature: 'user login',
      platform: 'Web',
    );

    expect(cases, hasLength(20));
    expect(cases.map((c) => c.title.toLowerCase()).toSet(), hasLength(20));

    for (final tc in cases) {
      expect(tc.module, 'login');
      expect(tc.feature, 'user login');
      expect(tc.platform, 'Web');
      expect(tc.actualResult, isEmpty);
      expect(tc.status, 'Not Executed');
      expect(tc.preconditions, isNotEmpty);
      expect(tc.steps.length, greaterThanOrEqualTo(3));
      expect(tc.expectedResult.length, greaterThan(60));

      final combined =
          '${tc.title} ${tc.expectedResult} ${tc.steps.map((s) => '${s.action} ${s.data} ${s.expected}').join(' ')}'
              .toLowerCase();
      expect(combined, isNot(contains('password123')));
      expect(combined, isNot(contains('user@example.com')));
      expect(combined, isNot(contains('dummy data')));
      expect(combined, isNot(contains('numeric input')));
      expect(combined, isNot(contains('checkout')));
      expect(combined, isNot(contains('payment')));
    }
  });

  test('canonical fallback maps cleanly to Excel and Xray exports', () {
    final cases = FallbackGenerator.generate(
      count: 3,
      module: 'login',
      feature: 'user login',
      platform: 'Web',
    );
    for (var i = 0; i < cases.length; i++) {
      cases[i].id = 'TC_LOGIN_${(i + 1).toString().padLeft(3, '0')}';
    }

    final excel = ExportMapper.toExcel(cases);
    final xray = ExportMapper.toXray(cases);

    expect(excel.first, contains('Test Data'));
    expect(excel.first, contains('Expected Result'));
    expect(excel, hasLength(4));
    expect(xray, hasLength(3));

    final firstXraySteps = xray.first['steps'] as List;
    expect(firstXraySteps.first['action'], isNotEmpty);
    expect(firstXraySteps.first['data'], isNotNull);
    expect(firstXraySteps.first['result'], isNotEmpty);
  });

  test('scenario planner returns exact core and pro skeleton counts', () {
    final corePlanner = ScenarioPlanner(
      module: 'login',
      feature: 'user login',
      platform: 'Web',
      mode: GenerationMode.balanced,
      count: 10,
      domain: 'general',
    );

    final proPlanner = ScenarioPlanner(
      module: 'login',
      feature: 'user login',
      platform: 'Web',
      mode: GenerationMode.balanced,
      count: 20,
      domain: 'general',
    );

    expect(corePlanner.generateSkeletons(), hasLength(10));
    expect(proPlanner.generateSkeletons(), hasLength(20));
  });

  test(
    'login fallback generates domain-aware cases without generic stability variants',
    () {
      final cases = FallbackGenerator.generate(
        count: 20,
        module: 'login',
        feature: 'user login',
        platform: 'Web',
      );

      expect(cases, hasLength(20));
      expect(
        cases.any(
          (tc) => tc.title.toLowerCase().contains('workflow stability'),
        ),
        isFalse,
      );
      expect(
        cases.any(
          (tc) => tc.title.toLowerCase().contains('default workflow stability'),
        ),
        isFalse,
      );
      expect(
        cases.any(
          (tc) =>
              tc.title.toLowerCase().contains('login') ||
              tc.title.toLowerCase().contains('password') ||
              tc.title.toLowerCase().contains('session') ||
              tc.title.toLowerCase().contains('authentication'),
        ),
        isTrue,
      );
    },
  );
}
