import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/orchestrator/deterministic_engine_v2.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';

void main() {
  group('DeterministicEngineV2', () {
    final results = <String, List<FinalizedTestCase>>{};
    final configs = [
      ('Auth', 'Login', 'WEB', 5),
      ('Auth', 'Login', 'Mobile', 3),
      ('Shop', 'Checkout', 'WEB', 5),
      ('Banking', 'Wire Transfer', 'WEB', 5),
      ('Medical', 'Patient Records', 'WEB', 3),
      ('Calendar', 'Book Appointment', 'WEB', 5),
      ('API', 'Webhook Integration', 'API', 5),
      ('ML', 'Model Training', 'WEB', 3),
      ('Social', 'Create Post', 'Mobile', 3),
      ('DevOps', 'Server Deploy', 'WEB', 5),
      ('Fleet', 'Robot Mission', 'API', 3),
    ];

    setUpAll(() async {
      for (final config in configs) {
        final engine = DeterministicEngineV2(
          module: config.$1,
          feature: config.$2,
          platform: config.$3,
          targetCount: config.$4,
        );
        results['${config.$1} / ${config.$2} (${config.$3})'] = await engine.generate();
      }
    });

    test('all 10 domains produce test cases', () {
      for (final entry in results.entries) {
        expect(entry.value, isNotEmpty,
            reason: '${entry.key} should produce test cases');
      }
    });

    test('each domain respects target count', () {
      for (int i = 0; i < configs.length; i++) {
        final key = '${configs[i].$1} / ${configs[i].$2} (${configs[i].$3})';
        final cases = results[key]!;
        expect(cases.length, configs[i].$4,
            reason: '$key should produce ${configs[i].$4} cases, got ${cases.length}');
      }
    });

    test('all test cases have required fields', () {
      for (final entry in results.entries) {
        for (int i = 0; i < entry.value.length; i++) {
          final tc = entry.value[i];
          expect(tc.title, isNotEmpty, reason: '${entry.key} TC $i: title empty');
          expect(tc.steps, isNotEmpty, reason: '${entry.key} TC $i: steps empty');
          expect(tc.expectedResult, isNotEmpty, reason: '${entry.key} TC $i: expectedResult empty');
          expect(tc.preconditions, isNotEmpty, reason: '${entry.key} TC $i: preconditions empty');
          expect(tc.id, isNotEmpty, reason: '${entry.key} TC $i: id empty');
          expect(tc.priority, isNotEmpty, reason: '${entry.key} TC $i: priority empty');
          expect(tc.type, isNotEmpty, reason: '${entry.key} TC $i: type empty');
        }
      }
    });

    test('titles use natural language', () {
      final templated = [
        'verify successful', 'verify error',
        'validate', 'boundary test:',
        'security:', 'session:',
      ];
      for (final entry in results.entries) {
        for (final tc in entry.value) {
          final lower = tc.title.toLowerCase();
          final hasTemplate = templated.any((p) => lower.startsWith(p));
          expect(hasTemplate, isFalse,
              reason: '${entry.key}: title "${tc.title}" starts with template phrase');
        }
      }
    });

    test('titles are descriptive (length >= 20 chars)', () {
      for (final entry in results.entries) {
        for (final tc in entry.value) {
          expect(tc.title.length, greaterThanOrEqualTo(20),
              reason: '${entry.key}: title "${tc.title}" too short (${tc.title.length})');
        }
      }
    });

    test('each test case has steps', () {
      for (final entry in results.entries) {
        for (final tc in entry.value) {
          expect(tc.steps.length, greaterThanOrEqualTo(1),
              reason: '${entry.key}: ${tc.id} has no steps');
        }
      }
    });

    test('steps contain platform-appropriate actions', () {
      for (final entry in results.entries) {
        final isWeb = entry.key.contains('WEB');
        final isMobile = entry.key.contains('Mobile');
        final isApi = entry.key.contains('API');
        for (final tc in entry.value) {
          final matched = tc.steps.where((step) {
            final a = step.action.toLowerCase();
            if (isWeb) {
              return a.contains('click') || a.contains('navigate') || a.contains('enter') || a.contains('submit')
                  || a.contains('open') || a.contains('go to') || a.contains('access') || a.contains('locate')
                  || a.contains('type') || a.contains('fill') || a.contains('press');
            }
            if (isMobile) {
              return a.contains('tap') || a.contains('open') || a.contains('enter') || a.contains('locate')
                  || a.contains('navigate') || a.contains('type');
            }
            if (isApi) {
              return a.contains('request') || a.contains('response') || a.contains('send') || a.contains('assert')
                  || a.contains('payload') || a.contains('body') || a.contains('status');
            }
            return true;
          }).length;
          expect(matched, greaterThanOrEqualTo(1),
              reason: '${entry.key}: ${tc.id} steps: ${tc.steps.map((s) => s.action).join(" | ")}');
        }
      }
    });

    test('priority is set correctly for all cases', () {
      for (final entry in results.entries) {
        for (final tc in entry.value) {
          expect(['High', 'Medium', 'Low'], contains(tc.priority),
              reason: '${entry.key}: ${tc.id} has invalid priority "${tc.priority}"');
        }
      }
    });

    test('preconditions contain domain-specific context', () {
      for (final entry in results.entries) {
        for (final tc in entry.value) {
          final all = tc.preconditions.join(' ').toLowerCase();
          expect(tc.preconditions.length, greaterThanOrEqualTo(2),
              reason: '${entry.key}: ${tc.id} has fewer than 2 preconditions');
          expect(all.length, greaterThan(30),
              reason: '${entry.key}: ${tc.id} preconditions too short');
        }
      }
    });

    test('expected results are detailed (>= 80 chars)', () {
      for (final entry in results.entries) {
        for (final tc in entry.value) {
          expect(tc.expectedResult.length, greaterThanOrEqualTo(80),
              reason: '${entry.key}: ${tc.id} expectedResult too short (${tc.expectedResult.length})');
        }
      }
    });

    test('test data contains key=value pairs', () {
      for (final entry in results.entries) {
        for (final tc in entry.value) {
          if (tc.testData.isNotEmpty) {
            expect(tc.testData, contains('='),
                reason: '${entry.key}: ${tc.id} testData missing key=value format');
          }
        }
      }
    });

    test('detailed quality report', () {
      print('\n======== DETERMINISTIC ENGINE V2 QUALITY REPORT ========');
      for (final entry in results.entries) {
        print('\n--- ${entry.key} (${entry.value.length} test cases) ---');
        for (int i = 0; i < entry.value.length; i++) {
          final tc = entry.value[i];
          print('  TC ${i + 1}: ${tc.id}');
          print('    Title: ${tc.title}');
          print('    Type: ${tc.type} | Priority: ${tc.priority}');
          print('    Steps: ${tc.steps.length}');
          print('    Preconditions: ${tc.preconditions.length}');
          print('    Expected: ${tc.expectedResult.substring(0, 60)}...');
          if (tc.testData.isNotEmpty) {
            print('    Data: ${tc.testData}');
          }
        }
      }
      print('\n========================================================\n');
    });
  });
}
