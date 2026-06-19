import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/usecases/export_validation_service.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

FinalizedTestCase _makeCase({
  String id = 'TC-001',
  String title = 'Valid test case',
  String priority = 'High',
  String expectedResult = 'Expected result',
  List<TestStep>? steps,
}) {
  return FinalizedTestCase(
    dbId: null,
    id: id,
    title: title,
    preconditions: [],
    testData: '',
    steps: steps ?? [TestStep(action: 'Perform action', data: '', expected: 'OK')],
    expectedResult: expectedResult,
    priority: priority,
    type: 'positive',
    module: 'Auth',
    feature: 'Login',
    platform: 'Web',
    source: CaseSource.ai,
  );
}

void main() {
  group('ExportValidationService', () {
    test('returns valid for non-empty suite', () {
      final result = ExportValidationService.validate([_makeCase()]);
      expect(result.isValid, true);
      expect(result.errors, isEmpty);
    });

    test('returns invalid for empty suite', () {
      final result = ExportValidationService.validate([]);
      expect(result.isValid, false);
      expect(result.errors, contains('Suite is empty. Nothing to export.'));
    });

    test('detects empty ID', () {
      final result = ExportValidationService.validate([_makeCase(id: '')]);
      expect(result.isValid, false);
      expect(result.errors, anyElement(contains('ID is empty')));
    });

    test('detects empty title', () {
      final result = ExportValidationService.validate([_makeCase(title: '')]);
      expect(result.isValid, false);
      expect(result.errors, anyElement(contains('Title is empty')));
    });

    test('detects no steps defined', () {
      final result = ExportValidationService.validate([_makeCase(steps: [])]);
      expect(result.isValid, false);
      expect(result.errors, anyElement(contains('No steps defined')));
    });

    test('detects empty step action', () {
      final result = ExportValidationService.validate([
        _makeCase(steps: [TestStep(action: '', data: '', expected: '')]),
      ]);
      expect(result.isValid, false);
      expect(result.errors, anyElement(contains('Action is empty')));
    });

    test('detects empty expected result', () {
      final result = ExportValidationService.validate([_makeCase(expectedResult: '')]);
      expect(result.isValid, false);
      expect(result.errors, anyElement(contains('Expected result is empty')));
    });

    test('detects invalid priority', () {
      final result = ExportValidationService.validate([_makeCase(priority: 'Urgent')]);
      expect(result.isValid, false);
      expect(result.errors, anyElement(contains('Invalid priority')));
    });

    test('detects duplicate IDs', () {
      final result = ExportValidationService.validate([
        _makeCase(id: 'TC-001', title: 'First'),
        _makeCase(id: 'TC-001', title: 'Duplicate'),
      ]);
      expect(result.isValid, false);
      expect(result.errors, anyElement(contains('Duplicate ID')));
    });

    test('collects multiple errors', () {
      final result = ExportValidationService.validate([
        _makeCase(id: '', title: '', priority: 'Bad', steps: []),
      ]);
      expect(result.errors.length, greaterThanOrEqualTo(4));
    });
  });
}
