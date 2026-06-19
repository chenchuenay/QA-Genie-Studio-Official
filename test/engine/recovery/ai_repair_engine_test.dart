import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/recovery/ai_repair_engine.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

WorkingCase makeCase({
  String id = 'TC_001',
  String title = 'Valid login test',
  String module = 'Auth',
  String feature = 'Login',
  String platform = 'WEB',
  String priority = 'High',
  String type = 'POSITIVE',
  String categoryLock = 'positive',
  String expectedResult = 'User is authenticated successfully',
  List<TestStep>? steps,
  List<String>? preconditions,
  String testData = 'email=test@test.com',
}) {
  return WorkingCase(
    id: id,
    title: title,
    module: module,
    feature: feature,
    platform: platform,
    priority: priority,
    type: type,
    categoryLock: categoryLock,
    preconditions: preconditions ?? ['User is authenticated'],
    testData: testData,
    steps: steps ?? [TestStep(action: 'Enter email', data: 'test@test.com', expected: 'Email accepted')],
    expectedResult: expectedResult,
    actualResult: '',
    status: 'Not Executed',
    metadata: CaseMetadata(source: CaseSource.ai, traceId: 'trace-1'),
    intentId: 'test_intent',
  );
}

void main() {
  group('AiRepairEngine', () {
    late AiRepairEngine engine;

    setUp(() {
      engine = AiRepairEngine();
    });

    group('repair', () {
      test('returns same list of cases', () {
        final cases = [makeCase()];
        final result = engine.repair(cases, 1);
        expect(result, same(cases));
        expect(result.length, equals(1));
      });

      test('enriches all fields for better quality', () {
        final tc = makeCase();
        final originalTitle = tc.title;
        engine.repair([tc], 1);
        expect(tc.title, equals(originalTitle));
        expect(tc.expectedResult.length, greaterThan(20));
      });
    });

    group('_enrichTitle', () {
      test('fills empty title with natural language description', () {
        final tc = makeCase(title: '');
        engine.repair([tc], 1);
        expect(tc.title.toLowerCase(), contains('login'));
        expect(tc.title.length, greaterThan(20));
      });

      test('does not modify non-empty title', () {
        final tc = makeCase(title: 'Custom test title');
        engine.repair([tc], 1);
        expect(tc.title, equals('Custom test title'));
      });
    });

    group('_enrichExpectedResult', () {
      test('fills empty expectedResult with rich domain-specific text', () {
        final tc = makeCase(expectedResult: '', categoryLock: 'positive');
        engine.repair([tc], 1);
        expect(tc.expectedResult.length, greaterThan(50));
        expect(tc.expectedResult, contains('dashboard'));
      });

      test('fills empty expectedResult for negative category', () {
        final tc = makeCase(expectedResult: '', categoryLock: 'negative');
        engine.repair([tc], 1);
        expect(tc.expectedResult, contains('error'));
      });

      test('fills empty expectedResult for security category', () {
        final tc = makeCase(expectedResult: '', categoryLock: 'security');
        engine.repair([tc], 1);
        expect(tc.expectedResult, contains('sanitized'));
      });

      test('fills empty expectedResult for session category', () {
        final tc = makeCase(expectedResult: '', categoryLock: 'session');
        engine.repair([tc], 1);
        expect(tc.expectedResult, contains('401'));
      });

      test('enriches short expectedResult with better text', () {
        final tc = makeCase(expectedResult: 'Custom expected');
        engine.repair([tc], 1);
        expect(tc.expectedResult.length, greaterThan(50));
        expect(tc.expectedResult, contains('dashboard'));
      });
    });

    group('_enrichSteps', () {
      test('creates multiple enriched steps when steps are empty', () {
        final tc = makeCase(steps: []);
        engine.repair([tc], 1);
        expect(tc.steps.length, equals(3));
        expect(tc.steps[0].action, contains('Navigate'));
      });

      test('fills empty action in steps', () {
        final tc = makeCase(steps: [TestStep(action: '', data: '', expected: 'done')]);
        engine.repair([tc], 1);
        expect(tc.steps[0].action, contains('Click'));
      });

      test('fills empty expected in steps', () {
        final tc = makeCase(steps: [TestStep(action: 'click', data: '', expected: '')]);
        engine.repair([tc], 1);
        expect(tc.steps[0].expected, isNotEmpty);
      });
    });

    group('_enrichPreconditions', () {
      test('adds multiple preconditions when empty', () {
        final tc = makeCase(preconditions: []);
        engine.repair([tc], 1);
        expect(tc.preconditions.length, greaterThanOrEqualTo(3));
        expect(tc.preconditions[0], contains('registered'));
        expect(tc.preconditions[1], contains('Login'));
      });

      test('keeps existing preconditions', () {
        final tc = makeCase(preconditions: ['Custom precondition']);
        engine.repair([tc], 1);
        expect(tc.preconditions, contains('Custom precondition'));
      });
    });

    group('_enrichTestData', () {
      test('fills empty testData with domain-specific values', () {
        final tc = makeCase(testData: '');
        engine.repair([tc], 1);
        expect(tc.testData, contains('admin@'));
        expect(tc.testData, contains('password'));
      });

      test('keeps existing testData', () {
        final tc = makeCase(testData: 'custom=data');
        engine.repair([tc], 1);
        expect(tc.testData, equals('custom=data'));
      });
    });
  });
}
