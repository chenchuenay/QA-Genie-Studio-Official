import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/usecases/export_test_cases_use_case.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/core/error/exceptions.dart';

final _validCase = FinalizedTestCase(
  dbId: null,
  id: 'TC-001',
  title: 'Valid test case',
  preconditions: [],
  testData: '',
  steps: [TestStep(action: 'Perform action', data: '', expected: 'Result')],
  expectedResult: 'Expected outcome',
  priority: 'High',
  type: 'positive',
  module: 'Auth',
  feature: 'Login',
  platform: 'Web',
  source: CaseSource.ai,
);

void main() {
  group('ExportTestCasesUseCase', () {
    test('execute with empty case list throws ExportException', () async {
      final useCase = ExportTestCasesUseCase();
      expect(
        () => useCase.execute(type: 'excel', cases: []),
        throwsA(isA<ExportException>()),
      );
    });

    test('execute with unsupported format throws ExportException', () async {
      final useCase = ExportTestCasesUseCase();
      expect(
        () => useCase.execute(type: 'unknown_format', cases: [_validCase]),
        throwsA(isA<ExportException>()),
      );
    });

    test('execute with invalid priority throws ExportException', () async {
      final invalidCase = _validCase.copyWith(priority: 'Invalid');
      final useCase = ExportTestCasesUseCase();
      expect(
        () => useCase.execute(type: 'excel', cases: [invalidCase]),
        throwsA(isA<ExportException>()),
      );
    });

    test('execute with empty ID throws ExportException', () async {
      final invalidCase = _validCase.copyWith(id: '');
      final useCase = ExportTestCasesUseCase();
      expect(
        () => useCase.execute(type: 'excel', cases: [invalidCase]),
        throwsA(isA<ExportException>()),
      );
    });
  });
}
