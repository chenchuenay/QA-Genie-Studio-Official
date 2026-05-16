import 'package:flutter_test/flutter_test.dart';

import 'support/live_http.dart';
import 'package:qa_genie/engine/generation_service.dart';
import 'package:qa_genie/data/models/test_case_model.dart';

const _liveAi = String.fromEnvironment('LIVE_AI') == '1';

void main() {
  ensureLiveGroqNetworking();

  Future<void> runSmoke(int count) async {
    final service = GenerationService();
    final result = await service.execute(
      module: 'login',
      feature: 'user login',
      platform: 'Web',
      maxCases: count,
    );
    final cases = result.cases;

    // ignore: avoid_print
    print('\nLIVE_GENERATION count=$count warning=${result.warning ?? 'none'}');
    for (final tc in cases) {
      // ignore: avoid_print
      print('- ${tc.id} | ${tc.type} | ${tc.priority} | ${tc.title}');
    }

    expect(cases, hasLength(count));
    expect(cases.map((c) => c.title.toLowerCase()).toSet(), hasLength(count));

    for (final tc in cases) {
      _expectCanonical(tc);
    }
  }

  test(
    'core generation returns 10 canonical export-safe cases',
    () async => runSmoke(10),
    skip: !_liveAi ? 'Set LIVE_AI=1 to run provider-backed smoke test.' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'pro generation returns 20 canonical export-safe cases',
    () async => runSmoke(20),
    skip: !_liveAi ? 'Set LIVE_AI=1 to run provider-backed smoke test.' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

void _expectCanonical(TestCaseModel tc) {
  expect(tc.id, isNotEmpty);
  expect(tc.module, 'login');
  expect(tc.feature, 'user login');
  expect(tc.platform, 'Web');
  expect(tc.actualResult, isEmpty);
  expect(tc.status, 'Not Executed');
  expect(tc.title.length, greaterThan(8));
  expect(tc.preconditions, isNotEmpty);
  expect(tc.steps.length, greaterThanOrEqualTo(3));
  expect(tc.expectedResult.length, greaterThan(60));

  final combined =
      '${tc.title} ${tc.expectedResult} ${tc.preconditions.join(' ')} ${tc.steps.map((s) => '${s.action} ${s.data} ${s.expected}').join(' ')}'
          .toLowerCase();
  for (final phrase in const [
    'works correctly',
    'behaves as expected',
    'application responds correctly',
    'maintains stable behavior',
    'dummy data',
    'password123',
    'user@example.com',
    'numeric input',
    'checkout',
    'payment',
  ]) {
    expect(combined, isNot(contains(phrase)), reason: tc.title);
  }

  for (final step in tc.steps) {
    expect(step.action.length, greaterThan(8), reason: tc.title);
    expect(step.expected.length, greaterThan(35), reason: tc.title);
  }
}
