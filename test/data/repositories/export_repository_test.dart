import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/data/repositories/export_repository.dart';
import 'package:qa_genie/domain/usecases/export_test_cases_use_case.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

class MockExportUseCase extends ExportTestCasesUseCase {
  String? lastType;
  List<FinalizedTestCase>? lastCases;
  String? lastModule;
  String? lastFeature;
  bool executeCalled = false;

  @override
  Future<void> execute({
    required String type,
    required List<FinalizedTestCase> cases,
    String? moduleName,
    String? featureName,
    String? adToken,
  }) async {
    executeCalled = true;
    lastType = type;
    lastCases = cases;
    lastModule = moduleName;
    lastFeature = featureName;
  }
}

FinalizedTestCase makeCase({String id = 'TC-001'}) {
  return FinalizedTestCase(
    dbId: null,
    id: id,
    title: 'Test case',
    preconditions: [],
    testData: '',
    steps: [TestStep(action: 'Step 1', data: '', expected: 'OK')],
    expectedResult: 'Expected',
    priority: 'Medium',
    type: 'positive',
    module: 'Auth',
    feature: 'Login',
    platform: 'Web',
    source: CaseSource.ai,
  );
}

void main() {
  group('ExportRepository', () {
    test('export delegates to use case', () async {
      final mock = MockExportUseCase();
      final repo = ExportRepository(exportUseCase: mock);
      final cases = [makeCase()];
      await repo.export(
        format: 'excel',
        cases: cases,
        moduleName: 'Auth',
        featureName: 'Login',
      );
      expect(mock.executeCalled, true);
      expect(mock.lastType, 'excel');
      expect(mock.lastCases, cases);
    });

    test('export with pdf format', () async {
      final mock = MockExportUseCase();
      final repo = ExportRepository(exportUseCase: mock);
      await repo.export(format: 'pdf', cases: [makeCase()], moduleName: 'M', featureName: 'F');
      expect(mock.lastType, 'pdf');
    });

    test('export with jira format', () async {
      final mock = MockExportUseCase();
      final repo = ExportRepository(exportUseCase: mock);
      await repo.export(format: 'jira', cases: [makeCase()], moduleName: 'M', featureName: 'F');
      expect(mock.lastType, 'jira');
    });

    test('export with xray format', () async {
      final mock = MockExportUseCase();
      final repo = ExportRepository(exportUseCase: mock);
      await repo.export(format: 'xray', cases: [makeCase()], moduleName: 'M', featureName: 'F');
      expect(mock.lastType, 'xray');
    });
  });
}
