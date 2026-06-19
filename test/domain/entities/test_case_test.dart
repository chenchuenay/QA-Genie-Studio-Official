import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/entities/test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';

void main() {
  final baseStep = TestStep(action: 'Enter email', data: 'user@test.com', expected: 'Field accepts');
  final base = TestCase(
    id: 'TC-001',
    title: 'Verify login with valid credentials',
    module: 'Authentication',
    feature: 'Login',
    platform: 'Web',
    priority: 'High',
    type: 'positive',
    categoryLock: 'positive',
    preconditions: ['User is on login page'],
    steps: [baseStep],
    expectedResult: 'User is redirected to dashboard',
    actualResult: '',
    status: 'Not Executed',
    source: 'AI',
    traceId: 'TRC-001',
    createdAt: 1000,
  );

  test('constructor sets all fields', () {
    expect(base.id, 'TC-001');
    expect(base.title, 'Verify login with valid credentials');
    expect(base.module, 'Authentication');
    expect(base.feature, 'Login');
    expect(base.platform, 'Web');
    expect(base.priority, 'High');
    expect(base.type, 'positive');
    expect(base.categoryLock, 'positive');
    expect(base.preconditions, ['User is on login page']);
    expect(base.steps, [baseStep]);
    expect(base.expectedResult, 'User is redirected to dashboard');
    expect(base.actualResult, '');
    expect(base.status, 'Not Executed');
    expect(base.source, 'AI');
    expect(base.traceId, 'TRC-001');
    expect(base.createdAt, 1000);
  });

  group('isExecutable', () {
    test('returns true when steps and expectedResult are present', () {
      expect(base.isExecutable, true);
    });

    test('returns false when steps is empty', () {
      final tc = TestCase(
        id: 'TC-002', title: 'Empty', module: 'M', feature: 'F',
        platform: 'Web', priority: 'Low', type: 'positive', categoryLock: 'positive',
        preconditions: [], steps: [], expectedResult: 'Done', actualResult: '',
        status: 'Not Executed', source: 'AI', traceId: 'T2', createdAt: 0,
      );
      expect(tc.isExecutable, false);
    });

    test('returns false when expectedResult is empty', () {
      final tc = TestCase(
        id: 'TC-003', title: 'Empty', module: 'M', feature: 'F',
        platform: 'Web', priority: 'Low', type: 'positive', categoryLock: 'positive',
        preconditions: [], steps: [baseStep], expectedResult: '', actualResult: '',
        status: 'Not Executed', source: 'AI', traceId: 'T3', createdAt: 0,
      );
      expect(tc.isExecutable, false);
    });
  });

  group('type checks', () {
    test('isPositive returns true for positive type', () {
      expect(base.isPositive, true);
    });

    test('isPositive returns false for non-positive', () {
      final tc = TestCase(
        id: 'TC-004', title: 'Neg', module: 'M', feature: 'F',
        platform: 'Web', priority: 'Low', type: 'negative', categoryLock: 'negative',
        preconditions: [], steps: [baseStep], expectedResult: 'Error', actualResult: '',
        status: 'Not Executed', source: 'AI', traceId: 'T4', createdAt: 0,
      );
      expect(tc.isPositive, false);
    });

    test('isNegative returns true for negative type', () {
      final tc = TestCase(
        id: 'TC-005', title: 'Neg', module: 'M', feature: 'F',
        platform: 'Web', priority: 'Low', type: 'negative', categoryLock: 'negative',
        preconditions: [], steps: [baseStep], expectedResult: 'Error', actualResult: '',
        status: 'Not Executed', source: 'AI', traceId: 'T5', createdAt: 0,
      );
      expect(tc.isNegative, true);
    });

    test('isSecurity checks categoryLock', () {
      final tc = TestCase(
        id: 'TC-006', title: 'Sec', module: 'M', feature: 'F',
        platform: 'Web', priority: 'High', type: 'security', categoryLock: 'security',
        preconditions: [], steps: [baseStep], expectedResult: 'Blocked', actualResult: '',
        status: 'Not Executed', source: 'AI', traceId: 'T6', createdAt: 0,
      );
      expect(tc.isSecurity, true);
    });
  });

  test('totalSteps returns steps length', () {
    final multi = TestCase(
      id: 'TC-007', title: 'Multi', module: 'M', feature: 'F',
      platform: 'Web', priority: 'Low', type: 'positive', categoryLock: 'positive',
      preconditions: [], steps: [baseStep, baseStep, baseStep], expectedResult: 'Done', actualResult: '',
      status: 'Not Executed', source: 'AI', traceId: 'T7', createdAt: 0,
    );
    expect(multi.totalSteps, 3);
  });
}
