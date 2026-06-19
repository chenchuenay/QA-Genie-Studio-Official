import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/validators/realism_validator.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

WorkingCase _makeCase({
  String title = 'Valid Login Test Case',
  String expectedResult = 'User is redirected to dashboard',
  String module = 'Auth',
  String feature = 'Login',
  String categoryLock = 'positive',
  String intentId = '__unknown__',
  String testData = '',
  List<String> preconditions = const [],
  List<TestStep>? steps,
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
    preconditions: preconditions,
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
  group('RealismValidator', () {
    group('validate', () {
      test('passes valid distinct cases', () {
        final rejected = <RejectedCaseInfo>[];
      final cases = [
        _makeCase(title: 'Login with valid credentials', module: 'Auth', feature: 'Login', expectedResult: 'User is redirected to dashboard'),
        _makeCase(title: 'Checkout with empty cart', module: 'Commerce', feature: 'Cart', expectedResult: 'Error message is displayed'),
      ];
        final result = RealismValidator.validate(cases, '', rejected.add);
        expect(result, hasLength(2));
        expect(rejected, isEmpty);
      });

      test('rejects duplicate titles', () {
        final rejected = <RejectedCaseInfo>[];
        final cases = [
          _makeCase(title: 'Duplicate Title'),
          _makeCase(title: 'Duplicate Title'),
        ];
        final result = RealismValidator.validate(cases, '', rejected.add);
        expect(result, hasLength(1));
        expect(rejected, hasLength(1));
        expect(rejected.first.reason, contains('Duplicate title'));
      });

      test('rejects generic titles', () {
        final rejected = <RejectedCaseInfo>[];
        final cases = [
          _makeCase(title: 'generic_positive_test'),
        ];
        final result = RealismValidator.validate(cases, '', rejected.add);
        expect(result, isEmpty);
        expect(rejected.first.reason, contains('Generic'));
      });

      test('rejects generic_negative titles', () {
        final rejected = <RejectedCaseInfo>[];
        final cases = [
          _makeCase(title: 'generic_negative_test'),
        ];
        final result = RealismValidator.validate(cases, '', rejected.add);
        expect(result, isEmpty);
      });

      test('rejects exact generic string', () {
        final rejected = <RejectedCaseInfo>[];
        final cases = [
          _makeCase(title: 'Positive test for apply promo code'),
        ];
        final result = RealismValidator.validate(cases, '', rejected.add);
        expect(result, isEmpty);
      });

      test('respects "only security" constraints', () {
        final rejected = <RejectedCaseInfo>[];
        final cases = [
          _makeCase(title: 'Test A', categoryLock: 'positive'),
        ];
        final result = RealismValidator.validate(
          cases,
          'only security',
          rejected.add,
        );
        expect(result, isEmpty);
        expect(rejected.first.reason, contains('Category not allowed'));
      });

      test('passes matching constraint', () {
        final rejected = <RejectedCaseInfo>[];
        final cases = [
          _makeCase(title: 'Security Test', categoryLock: 'security'),
        ];
        final result = RealismValidator.validate(
          cases,
          'only security',
          rejected.add,
        );
        expect(result, hasLength(1));
      });

      test('rejects semantic duplicates', () {
        final rejected = <RejectedCaseInfo>[];
        final cases = [
          _makeCase(
            title: 'Login Test One',
            module: 'Auth',
            feature: 'Login',
          ),
          _makeCase(
            title: 'Login Test Two',
            module: 'Auth',
            feature: 'Login',
          ),
        ];
        final result = RealismValidator.validate(cases, '', rejected.add);
        expect(result, hasLength(1));
        expect(rejected.first.reason, contains('Semantic duplicate'));
      });
    });

    group('isValid', () {
      test('returns false for generic title', () {
        final tc = FinalizedTestCase(
          id: '1',
          title: 'generic_test',
          preconditions: [],
          testData: '',
          steps: [TestStep(action: 'do')],
          expectedResult: 'works',
          priority: 'Medium',
          type: 'Functional',
          module: 'M',
          feature: 'F',
          platform: 'A',
        );
        expect(RealismValidator.isValid(tc), isFalse);
      });

      test('returns false for sample title', () {
        final tc = FinalizedTestCase(
          id: '1',
          title: 'sample test case',
          preconditions: [],
          testData: '',
          steps: [TestStep(action: 'do')],
          expectedResult: 'works',
          priority: 'Medium',
          type: 'Functional',
          module: 'M',
          feature: 'F',
          platform: 'A',
        );
        expect(RealismValidator.isValid(tc), isFalse);
      });

      test('returns false for short title', () {
        final tc = FinalizedTestCase(
          id: '1',
          title: 'Too short',
          preconditions: [],
          testData: '',
          steps: [TestStep(action: 'do')],
          expectedResult: 'works',
          priority: 'Medium',
          type: 'Functional',
          module: 'M',
          feature: 'F',
          platform: 'A',
        );
        expect(RealismValidator.isValid(tc), isFalse);
      });

      test('returns false for empty steps', () {
        final tc = FinalizedTestCase(
          id: '1',
          title: 'Valid Long Test Case Title',
          preconditions: [],
          testData: '',
          steps: [],
          expectedResult: 'works',
          priority: 'Medium',
          type: 'Functional',
          module: 'M',
          feature: 'F',
          platform: 'A',
        );
        expect(RealismValidator.isValid(tc), isFalse);
      });

      test('returns false for empty expected result', () {
        final tc = FinalizedTestCase(
          id: '1',
          title: 'Valid Long Test Case Title',
          preconditions: [],
          testData: '',
          steps: [TestStep(action: 'do')],
          expectedResult: '',
          priority: 'Medium',
          type: 'Functional',
          module: 'M',
          feature: 'F',
          platform: 'A',
        );
        expect(RealismValidator.isValid(tc), isFalse);
      });

      test('returns true for valid finalized case', () {
        final tc = FinalizedTestCase(
          id: '1',
          title: 'Valid Test Case Description Here',
          preconditions: [],
          testData: '',
          steps: [TestStep(action: 'do')],
          expectedResult: 'Should work correctly',
          priority: 'Medium',
          type: 'Functional',
          module: 'M',
          feature: 'F',
          platform: 'A',
        );
        expect(RealismValidator.isValid(tc), isTrue);
      });
    });
  });
}
