import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/validators/structural_validator.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

WorkingCase _makeCase({
  String id = 'TC-001',
  String title = 'Valid Test Case',
  String expectedResult = 'Should pass',
  List<TestStep>? steps,
}) {
  return WorkingCase(
    id: id,
    title: title,
    module: 'Auth',
    feature: 'Login',
    platform: 'Android',
    priority: 'High',
    type: 'Functional',
    categoryLock: 'positive',
    preconditions: [],
    testData: '',
    steps: steps ?? [TestStep(action: 'Click login', expected: 'Opens')],
    expectedResult: expectedResult,
    actualResult: '',
    status: 'Not Executed',
    metadata: CaseMetadata(source: CaseSource.ai, traceId: 'trace-1'),
  );
}

void main() {
  group('StructuralValidator', () {
    late StructuralValidator validator;

    setUp(() {
      validator = const StructuralValidator();
    });

    test('passes for valid case', () {
      final result = validator.validateSingle(_makeCase());
      expect(result.isValid, isTrue);
      expect(result.reason, isNull);
    });

    test('fails when title is empty', () {
      final result = validator.validateSingle(_makeCase(title: ''));
      expect(result.isValid, isFalse);
      expect(result.reason, contains('Title'));
    });

    test('fails when title is whitespace', () {
      final result = validator.validateSingle(_makeCase(title: '   '));
      expect(result.isValid, isFalse);
      expect(result.reason, contains('Title'));
    });

    test('fails when id is empty', () {
      final result = validator.validateSingle(_makeCase(id: ''));
      expect(result.isValid, isFalse);
      expect(result.reason, contains('ID'));
    });

    test('fails when expectedResult is empty', () {
      final result = validator.validateSingle(_makeCase(expectedResult: ''));
      expect(result.isValid, isFalse);
      expect(result.reason, contains('expected result'));
    });

    test('fails when steps is empty', () {
      final result = validator.validateSingle(_makeCase(steps: []));
      expect(result.isValid, isFalse);
      expect(result.reason, contains('steps'));
    });

    test('fails when a step has empty action', () {
      final result = validator.validateSingle(_makeCase(
        steps: [TestStep(action: '', expected: 'something')],
      ));
      expect(result.isValid, isFalse);
      expect(result.reason, contains('action is empty'));
    });

    test('fails when a step has whitespace-only action', () {
      final result = validator.validateSingle(_makeCase(
        steps: [TestStep(action: '   ', expected: 'something')],
      ));
      expect(result.isValid, isFalse);
      expect(result.reason, contains('action is empty'));
    });

    test('reports correct step index in error', () {
      final result = validator.validateSingle(_makeCase(
        steps: [
          TestStep(action: 'First', expected: 'Ok'),
          TestStep(action: '', expected: 'Fail'),
        ],
      ));
      expect(result.isValid, isFalse);
      expect(result.reason, contains('Step 2'));
    });
  });
}
