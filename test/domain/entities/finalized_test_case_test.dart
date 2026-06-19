import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

void main() {
  final step = TestStep(action: 'Enter email', data: 'user@test.com', expected: 'Field accepts');
  final base = FinalizedTestCase(
    dbId: 1,
    id: 'TC-001',
    title: 'Verify login',
    preconditions: ['User is on login page'],
    testData: 'admin@demo.com',
    steps: [step],
    expectedResult: 'Dashboard loads',
    actualResult: '',
    priority: 'High',
    status: 'Not Executed',
    type: 'positive',
    module: 'Auth',
    feature: 'Login',
    platform: 'Web',
    source: CaseSource.ai,
  );

  test('constructor sets all fields with defaults', () {
    expect(base.dbId, 1);
    expect(base.id, 'TC-001');
    expect(base.title, 'Verify login');
    expect(base.preconditions, ['User is on login page']);
    expect(base.testData, 'admin@demo.com');
    expect(base.steps, [step]);
    expect(base.expectedResult, 'Dashboard loads');
    expect(base.actualResult, '');
    expect(base.priority, 'High');
    expect(base.status, 'Not Executed');
    expect(base.type, 'positive');
    expect(base.module, 'Auth');
    expect(base.feature, 'Login');
    expect(base.platform, 'Web');
    expect(base.source, CaseSource.ai);
  });

  test('constructor uses default status and source', () {
    final tc = FinalizedTestCase(
      dbId: null, id: 'TC-002', title: 'Test', preconditions: [],
      testData: '', steps: [step], expectedResult: 'OK',
      priority: 'Low', type: 'negative', module: 'M', feature: 'F', platform: 'Web',
    );
    expect(tc.status, 'Not Executed');
    expect(tc.source, CaseSource.ai);
  });

  group('copyWith', () {
    test('returns identical copy with no args', () {
      final copy = base.copyWith();
      expect(copy.dbId, base.dbId);
      expect(copy.id, base.id);
      expect(copy.title, base.title);
      expect(copy.source, base.source);
    });

    test('overrides specified fields', () {
      final copy = base.copyWith(title: 'New title', priority: 'Low');
      expect(copy.title, 'New title');
      expect(copy.priority, 'Low');
      expect(copy.dbId, 1);
    });

    test('dbId sentinel sets to null', () {
      final copy = base.copyWith(dbId: null);
      expect(copy.dbId, null);
    });

    test('preconditions is a new list', () {
      final copy = base.copyWith();
      copy.preconditions.add('Extra');
      expect(base.preconditions.length, 1);
    });
  });
}
