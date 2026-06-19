import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/validators/export_safety_validator.dart';
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
  group('ExportSafetyValidator', () {
    late ExportSafetyValidator validator;

    setUp(() {
      validator = const ExportSafetyValidator();
    });

    test('fails for empty cases list', () {
      final result = validator.validate([]);
      expect(result.isSuccessful, isFalse);
      expect(result.errors, hasLength(1));
      expect(result.errors.first, contains('zero finalized cases'));
    });

    test('passes for valid cases', () {
      final result = validator.validate([_makeCase()]);
      expect(result.isSuccessful, isTrue);
      expect(result.errors, isEmpty);
    });

    test('reports missing ID', () {
      final result = validator.validate([_makeCase(id: '')]);
      expect(result.isSuccessful, isFalse);
      expect(result.errors.any((e) => e.contains('missing ID')), isTrue);
    });

    test('reports missing title', () {
      final result = validator.validate([_makeCase(title: '')]);
      expect(result.isSuccessful, isFalse);
      expect(result.errors.any((e) => e.contains('missing title')), isTrue);
    });

    test('reports missing expected result', () {
      final result = validator.validate([_makeCase(expectedResult: '')]);
      expect(result.isSuccessful, isFalse);
      expect(result.errors.any((e) => e.contains('missing expected result')), isTrue);
    });

    test('reports missing steps', () {
      final result = validator.validate([_makeCase(steps: [])]);
      expect(result.isSuccessful, isFalse);
      expect(result.errors.any((e) => e.contains('missing steps')), isTrue);
    });

    test('reports missing step action', () {
      final result = validator.validate([
        _makeCase(steps: [TestStep(action: '', expected: 'Opens')]),
      ]);
      expect(result.isSuccessful, isFalse);
      expect(result.errors.any((e) => e.contains('step 1 missing action')), isTrue);
    });

    test('reports missing step expected result', () {
      final result = validator.validate([
        _makeCase(steps: [TestStep(action: 'Click', expected: '')]),
      ]);
      expect(result.isSuccessful, isFalse);
      expect(result.errors.any((e) => e.contains('step 1 missing expected result')), isTrue);
    });

    test('detects <script> injection in title', () {
      final result = validator.validate([
        _makeCase(title: '<script>alert("xss")</script>'),
      ]);
      expect(result.isSuccessful, isFalse);
      expect(result.errors.any((e) => e.contains('unsafe title')), isTrue);
    });

    test('detects SQL injection in expectedResult', () {
      final result = validator.validate([
        _makeCase(expectedResult: 'DROP TABLE users;--'),
      ]);
      expect(result.isSuccessful, isFalse);
      expect(result.errors.any((e) => e.contains('unsafe expected result')), isTrue);
    });

    test('detects -- injection', () {
      final result = validator.validate([
        _makeCase(title: 'comment -- injection'),
      ]);
      expect(result.isSuccessful, isFalse);
      expect(result.errors.any((e) => e.contains('unsafe')), isTrue);
    });

    test('collects multiple errors', () {
      final result = validator.validate([
        _makeCase(
          id: '',
          title: '',
          expectedResult: '',
          steps: [TestStep(action: '', expected: '')],
        ),
      ]);
      expect(result.isSuccessful, isFalse);
      expect(result.errors.length, greaterThanOrEqualTo(5));
    });
  });
}
