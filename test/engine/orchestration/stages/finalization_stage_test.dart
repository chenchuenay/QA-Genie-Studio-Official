import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/engine/orchestration/stages/finalization_stage.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

WorkingCase makeCase({
  String title = 'Test case title',
  String module = 'Auth',
  String feature = 'Login',
  String platform = 'WEB',
  String id = 'WC_001',
  String type = 'POSITIVE',
  String priority = 'High',
}) {
  return WorkingCase(
    id: id,
    title: title,
    module: module,
    feature: feature,
    platform: platform,
    priority: priority,
    type: type,
    categoryLock: 'positive',
    preconditions: ['User is authenticated'],
    testData: 'email=test@test.com',
    steps: [TestStep(action: 'Enter email', data: 'test@test.com', expected: 'Email accepted')],
    expectedResult: 'Operation succeeds',
    actualResult: '',
    status: '',
    metadata: CaseMetadata(source: CaseSource.ai, traceId: 'trace-1'),
    intentId: '',
  );
}

void main() {
  group('FinalizationStage', () {
    test('execute converts WorkingCase to FinalizedTestCase', () {
      final stage = FinalizationStage();
      final cases = [makeCase()];
      final result = stage.execute(cases: cases, module: 'Auth');
      expect(result.length, equals(1));
      expect(result[0], isA<FinalizedTestCase>());
    });

    test('execute generates sequential TC IDs', () {
      final stage = FinalizationStage();
      final cases = [makeCase(), makeCase()];
      final result = stage.execute(cases: cases, module: 'Auth');
      expect(result[0].id, equals('TC_AUTH_001'));
      expect(result[1].id, equals('TC_AUTH_002'));
    });

    test('execute normalizes module name for IDs', () {
      final stage = FinalizationStage();
      final cases = [makeCase(module: 'User Auth')];
      final result = stage.execute(cases: cases, module: 'User Auth');
      expect(result[0].id, equals('TC_USER_AUTH_001'));
    });

    test('execute copies all fields properly', () {
      final stage = FinalizationStage();
      final tc = makeCase(
        title: 'Test login success',
        module: 'Login',
        feature: 'Sign In',
        platform: 'Mobile',
        priority: 'High',
        type: 'POSITIVE',
      );
      final result = stage.execute(cases: [tc], module: 'Login');
      expect(result[0].title, equals('Test login success'));
      expect(result[0].module, equals('Login'));
      expect(result[0].feature, equals('Sign In'));
      expect(result[0].platform, equals('Mobile'));
      expect(result[0].priority, equals('High'));
      expect(result[0].type, equals('POSITIVE'));
      expect(result[0].source, equals(CaseSource.ai));
      expect(result[0].status, equals('Not Executed'));
    });

    test('execute normalizes whitespace in titles', () {
      final stage = FinalizationStage();
      final tc = makeCase(title: '  Test   with   extra   spaces  ');
      final result = stage.execute(cases: [tc], module: 'Test');
      expect(result[0].title, equals('Test with extra spaces'));
    });

    test('execute handles empty input', () {
      final stage = FinalizationStage();
      final result = stage.execute(cases: [], module: 'Empty');
      expect(result, isEmpty);
    });
  });
}
