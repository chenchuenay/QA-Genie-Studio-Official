import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/entities/test_suite.dart';
import 'package:qa_genie/domain/entities/test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';

void main() {
  final step = TestStep(action: 'Click', data: '', expected: 'Done');
  final tc = TestCase(
    id: 'TC-001', title: 'Test', module: 'M', feature: 'F',
    platform: 'Web', priority: 'Low', type: 'positive', categoryLock: 'positive',
    preconditions: [], steps: [step], expectedResult: 'Done', actualResult: '',
    status: 'Not Executed', source: 'AI', traceId: 'T', createdAt: 0,
  );

  group('TestSuite', () {
    test('constructor sets fields', () {
      final suite = TestSuite(
        id: 'S-001', name: 'Login Tests', module: 'Auth', feature: 'Login',
        generationMode: 'CORE', traceId: 'TRC-1', testCases: [tc],
        createdAt: 1000, totalCases: 1,
      );
      expect(suite.id, 'S-001');
      expect(suite.name, 'Login Tests');
      expect(suite.module, 'Auth');
      expect(suite.feature, 'Login');
      expect(suite.generationMode, 'CORE');
      expect(suite.traceId, 'TRC-1');
      expect(suite.testCases, [tc]);
      expect(suite.createdAt, 1000);
      expect(suite.totalCases, 1);
    });

    test('isEmpty returns true when no test cases', () {
      final suite = TestSuite(
        id: 'S-002', name: 'Empty', module: 'M', feature: 'F',
        generationMode: 'CORE', traceId: 'T', testCases: [],
        createdAt: 0, totalCases: 0,
      );
      expect(suite.isEmpty, true);
    });

    test('isEmpty returns false when test cases exist', () {
      final suite = TestSuite(
        id: 'S-003', name: 'NonEmpty', module: 'M', feature: 'F',
        generationMode: 'CORE', traceId: 'T', testCases: [tc],
        createdAt: 0, totalCases: 1,
      );
      expect(suite.isEmpty, false);
    });

    test('isPro returns true for PRO mode', () {
      final suite = TestSuite(
        id: 'S-004', name: 'Pro', module: 'M', feature: 'F',
        generationMode: 'PRO', traceId: 'T', testCases: [],
        createdAt: 0, totalCases: 0,
      );
      expect(suite.isPro, true);
    });

    test('isPro returns false for CORE mode', () {
      final suite = TestSuite(
        id: 'S-005', name: 'Core', module: 'M', feature: 'F',
        generationMode: 'CORE', traceId: 'T', testCases: [],
        createdAt: 0, totalCases: 0,
      );
      expect(suite.isPro, false);
    });

    test('hasConstraints returns true when constraints non-empty', () {
      final suite = TestSuite(
        id: 'S-006', name: 'Constrained', module: 'M', feature: 'F',
        generationMode: 'CORE', traceId: 'T', testCases: [],
        createdAt: 0, totalCases: 0, constraints: 'WCAG 2.1',
      );
      expect(suite.hasConstraints, true);
    });

    test('hasConstraints returns false when constraints null', () {
      expect(baseSuite().hasConstraints, false);
    });

    test('hasConstraints returns false when constraints empty', () {
      final suite = TestSuite(
        id: 'S-007', name: 'Empty constraints', module: 'M', feature: 'F',
        generationMode: 'CORE', traceId: 'T', testCases: [],
        createdAt: 0, totalCases: 0, constraints: '',
      );
      expect(suite.hasConstraints, false);
    });
  });
}

TestCase _baseTestCase() {
  final step = TestStep(action: 'Click', data: '', expected: 'Done');
  return TestCase(
    id: 'TC-001', title: 'Test', module: 'M', feature: 'F',
    platform: 'Web', priority: 'Low', type: 'positive', categoryLock: 'positive',
    preconditions: [], steps: [step], expectedResult: 'Done', actualResult: '',
    status: 'Not Executed', source: 'AI', traceId: 'T', createdAt: 0,
  );
}

TestSuite baseSuite() {
  return TestSuite(
    id: 'S-001', name: 'Base', module: 'M', feature: 'F',
    generationMode: 'CORE', traceId: 'T', testCases: [_baseTestCase()],
    createdAt: 0, totalCases: 1,
  );
}
