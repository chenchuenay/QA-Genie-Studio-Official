import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/validators/semantic_validator.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

WorkingCase _makeCase({
  String title = 'Valid Login Test Case',
  String expectedResult = 'User should be redirected',
  List<TestStep>? steps,
  String module = 'Auth',
  String feature = 'Login',
  String categoryLock = 'positive',
  String intentId = '__unknown__',
  String testData = '',
}) {
  return WorkingCase(
    id: 'TC-001',
    title: title,
    module: module,
    feature: feature,
    platform: 'Android',
    priority: 'High',
    type: 'Functional',
    categoryLock: categoryLock,
    preconditions: [],
    testData: testData,
    steps: steps ?? [TestStep(action: 'Enter credentials', expected: 'Field updated')],
    expectedResult: expectedResult,
    actualResult: '',
    status: 'Not Executed',
    metadata: CaseMetadata(source: CaseSource.ai, traceId: 'trace-1'),
    intentId: intentId,
  );
}

void main() {
  group('SemanticValidator', () {
    late SemanticValidator validator;

    setUp(() {
      validator = SemanticValidator();
    });

    test('passes valid cases', () {
      final rejected = <RejectedCaseInfo>[];
      final result = validator.validate(
        [_makeCase()],
        rejected.add,
      );
      expect(result.validCases, hasLength(1));
      expect(result.rejectedReasons, isEmpty);
      expect(rejected, isEmpty);
    });

    test('rejects case with title shorter than 8 characters', () {
      final rejected = <RejectedCaseInfo>[];
      final result = validator.validate(
        [_makeCase(title: 'Short')],
        rejected.add,
      );
      expect(result.validCases, isEmpty);
      expect(result.rejectedReasons[0], contains('Semantically weak title'));
      expect(rejected, hasLength(1));
      expect(rejected.first.stage, 'SemanticValidation');
    });

    test('rejects case with repetitive actions (garbage)', () {
      final rejected = <RejectedCaseInfo>[];
      final tc = _makeCase(
        title: 'Test With Repetitive Steps Here',
        steps: [
          TestStep(action: 'tap tap', expected: 'a'),
          TestStep(action: 'tap tap', expected: 'b'),
          TestStep(action: 'tap tap', expected: 'c'),
        ],
      );
      final result = validator.validate([tc], rejected.add);
      expect(result.validCases, isEmpty);
      expect(result.rejectedReasons[0], contains('Repetitive'));
    });

    test('rejects case with placeholder expected result', () {
      final rejected = <RejectedCaseInfo>[];
      final result = validator.validate(
        [_makeCase(expectedResult: 'lorem ipsum dolor sit amet')],
        rejected.add,
      );
      expect(result.validCases, isEmpty);
      expect(result.rejectedReasons[0], contains('Placeholder'));
    });

    test('rejects case with dummy placeholder', () {
      final rejected = <RejectedCaseInfo>[];
      final result = validator.validate(
        [_makeCase(expectedResult: 'this is a dummy response')],
        rejected.add,
      );
      expect(result.validCases, isEmpty);
    });

    test('rejects case with sample response placeholder', () {
      final rejected = <RejectedCaseInfo>[];
      final result = validator.validate(
        [_makeCase(expectedResult: 'sample response here')],
        rejected.add,
      );
      expect(result.validCases, isEmpty);
    });

    test('extracts semantic profile for login', () {
      final rejected = <RejectedCaseInfo>[];
      final tc = _makeCase(title: 'User Login Test');
      final result = validator.validate([tc], rejected.add);
      expect(result.validCases.first.metadata.semanticProfile, 'security');
    });

    test('extracts semantic profile for payment', () {
      final rejected = <RejectedCaseInfo>[];
      final tc = _makeCase(title: 'Payment Checkout Flow');
      final result = validator.validate([tc], rejected.add);
      expect(result.validCases.first.metadata.semanticProfile, 'validation');
    });

    test('extracts semantic profile for session', () {
      final rejected = <RejectedCaseInfo>[];
      final tc = _makeCase(title: 'Session Timeout Handling');
      final result = validator.validate([tc], rejected.add);
      expect(result.validCases.first.metadata.semanticProfile, 'session');
    });

    test('extracts semantic profile for accessibility', () {
      final rejected = <RejectedCaseInfo>[];
      final tc = _makeCase(title: 'Accessibility Screen Reader');
      final result = validator.validate([tc], rejected.add);
      expect(result.validCases.first.metadata.semanticProfile, 'usability');
    });

    test('extracts semantic profile for offline', () {
      final rejected = <RejectedCaseInfo>[];
      final tc = _makeCase(title: 'Offline Retry Mechanism');
      final result = validator.validate([tc], rejected.add);
      expect(result.validCases.first.metadata.semanticProfile, 'resilience');
    });

    test('extracts functional profile as default', () {
      final rejected = <RejectedCaseInfo>[];
      final tc = _makeCase(title: 'Generic UI Element Test');
      final result = validator.validate([tc], rejected.add);
      expect(result.validCases.first.metadata.semanticProfile, 'functional');
    });

    test('builds fingerprint with failure mode neg', () {
      final rejected = <RejectedCaseInfo>[];
      final tc = _makeCase(expectedResult: 'Should show error message');
      final result = validator.validate([tc], rejected.add);
      expect(result.validCases.first.metadata.fingerprint, contains('|neg|'));
    });

    test('builds fingerprint with failure mode pos', () {
      final rejected = <RejectedCaseInfo>[];
      final tc = _makeCase(expectedResult: 'User should be redirected');
      final result = validator.validate([tc], rejected.add);
      expect(result.validCases.first.metadata.fingerprint, contains('|pos|'));
    });

    test('handles empty input', () {
      final rejected = <RejectedCaseInfo>[];
      final result = validator.validate([], rejected.add);
      expect(result.validCases, isEmpty);
      expect(result.rejectedReasons, isEmpty);
    });
  });
}
