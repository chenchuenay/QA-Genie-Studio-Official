import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/usecases/save_suite_use_case.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/data/repositories/suite_repository.dart';
import 'package:qa_genie/data/datasources/local/local_db_source.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';

class MockLocalDbSourceForSave extends LocalDbSource {
  final Map<int, Map<String, dynamic>> _suites = {};
  final Map<int, List<FinalizedTestCase>> _cases = {};
  int _nextId = 1;

  @override
  Future<int> createSuite({required String moduleName, required String feature, required String platform}) async {
    final id = _nextId++;
    _suites[id] = {'id': id, 'moduleName': moduleName, 'feature': feature, 'platform': platform};
    _cases[id] = [];
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllSuites() async => _suites.values.toList();

  @override
  Future<void> deleteSuite(int suiteId) async {
    _suites.remove(suiteId);
    _cases.remove(suiteId);
  }

  @override
  Future<List<FinalizedTestCase>> getTestCasesForSuite(int suiteId) async => _cases[suiteId] ?? [];

  @override
  Future<void> insertTestCases({required int suiteId, required List<FinalizedTestCase> cases}) async {
    _cases[suiteId] ??= [];
    for (final tc in cases) {
      _cases[suiteId]!.add(tc.copyWith(dbId: _nextId++));
    }
  }

  @override
  Future<void> updateSuiteCases({required int suiteId, required List<FinalizedTestCase> cases}) async {
    _cases[suiteId] = [];
    for (final tc in cases) {
      _cases[suiteId]!.add(tc.copyWith(dbId: _nextId++));
    }
  }

  @override
  Future<void> insertSingleCase({required int suiteId, required FinalizedTestCase testCase}) async {
    _cases[suiteId] ??= [];
    _cases[suiteId]!.add(testCase.copyWith(dbId: _nextId++));
  }

  @override
  Future<void> deleteTestCase(int dbId) async {
    for (final suiteId in _cases.keys) {
      _cases[suiteId]!.removeWhere((tc) => tc.dbId == dbId);
    }
  }

  @override
  Future<void> copyTestCase({required int targetSuiteId, required FinalizedTestCase testCase}) async {
    _cases[targetSuiteId] ??= [];
    _cases[targetSuiteId]!.add(testCase.copyWith(dbId: _nextId++));
  }

  @override
  Future<void> moveTestCase({required int sourceSuiteId, required int targetSuiteId, required FinalizedTestCase testCase}) async {
    await copyTestCase(targetSuiteId: targetSuiteId, testCase: testCase);
    if (testCase.dbId != null) {
      _cases[sourceSuiteId]?.removeWhere((tc) => tc.dbId == testCase.dbId);
    }
  }

  @override
  Future<void> replaceSingleCase({required int suiteId, required FinalizedTestCase updatedCase}) async {
    if (updatedCase.dbId == null) return;
    final cases = _cases[suiteId];
    if (cases == null) return;
    final index = cases.indexWhere((tc) => tc.dbId == updatedCase.dbId);
    if (index != -1) cases[index] = updatedCase;
  }
}

FinalizedTestCase makeCase({String id = 'TC-001', String title = 'Test case'}) {
  return FinalizedTestCase(
    dbId: null, id: id, title: title, preconditions: [], testData: '',
    steps: [TestStep(action: 'A', data: '', expected: 'B')], expectedResult: 'R',
    priority: 'Medium', type: 'positive', module: 'M', feature: 'F', platform: 'Web',
    source: CaseSource.ai,
  );
}

void main() {
  late SaveSuiteUseCase useCase;
  late SuiteRepository repo;

  setUp(() {
    repo = SuiteRepository(local: MockLocalDbSourceForSave());
    useCase = SaveSuiteUseCase(repository: repo);
  });

  group('SaveSuiteUseCase', () {
    test('createSuite returns id', () async {
      final id = await useCase.createSuite(module: 'Auth', feature: 'Login', platform: 'Web');
      expect(id, greaterThan(0));
    });

    test('syncSession persists session cases', () async {
      final id = await useCase.createSuite(module: 'M', feature: 'F', platform: 'Web');
      final session = GenerationSession(
        traceId: 'trace-1',
        testCases: [makeCase(id: 'TC-1', title: 'Synced')],
        auditReport: const PipelineAuditReport(traceId: 'trace-1'),
      );
      await useCase.syncSession(suiteId: id, session: session);
      final cases = await repo.getTestCases(id);
      expect(cases.length, 1);
    });

    test('saveSuite replaces all cases', () async {
      final id = await useCase.createSuite(module: 'M', feature: 'F', platform: 'Web');
      await useCase.saveSuite(suiteId: id, cases: [makeCase(id: 'TC-1', title: 'One')]);
      await useCase.saveSuite(suiteId: id, cases: [makeCase(id: 'TC-2', title: 'Two')]);
      final cases = await repo.getTestCases(id);
      expect(cases.length, 1);
      expect(cases.first.title, 'Two');
    });

    test('update is alias for saveSuite', () async {
      final id = await useCase.createSuite(module: 'M', feature: 'F', platform: 'Web');
      await useCase.update(suiteId: id, cases: [makeCase(id: 'TC-U')]);
      final cases = await repo.getTestCases(id);
      expect(cases.length, 1);
    });

    test('addCase appends a case', () async {
      final id = await useCase.createSuite(module: 'M', feature: 'F', platform: 'Web');
      await useCase.addCase(suiteId: id, testCase: makeCase(id: 'TC-A1'));
      await useCase.addCase(suiteId: id, testCase: makeCase(id: 'TC-A2'));
      final cases = await repo.getTestCases(id);
      expect(cases.length, 2);
    });

    test('deleteCase removes case by dbId', () async {
      final id = await useCase.createSuite(module: 'M', feature: 'F', platform: 'Web');
      await useCase.addCase(suiteId: id, testCase: makeCase(id: 'TC-D'));
      final cases = await repo.getTestCases(id);
      expect(cases.length, 1);
      if (cases.first.dbId != null) {
        await useCase.deleteCase(cases.first.dbId!);
      }
      expect(await repo.getTestCases(id), isEmpty);
    });

    test('copyCase copies to target suite', () async {
      final src = await useCase.createSuite(module: 'Src', feature: 'F', platform: 'Web');
      final dst = await useCase.createSuite(module: 'Dst', feature: 'F', platform: 'Web');
      await useCase.addCase(suiteId: src, testCase: makeCase(id: 'TC-C'));
      final srcCases = await repo.getTestCases(src);
      await useCase.copyCase(targetSuiteId: dst, testCase: srcCases.first);
      expect(await repo.getTestCases(dst), hasLength(1));
    });

    test('moveCase moves case between suites', () async {
      final src = await useCase.createSuite(module: 'SrcM', feature: 'F', platform: 'Web');
      final dst = await useCase.createSuite(module: 'DstM', feature: 'F', platform: 'Web');
      await useCase.addCase(suiteId: src, testCase: makeCase(id: 'TC-M'));
      final srcCases = await repo.getTestCases(src);
      await useCase.moveCase(sourceSuiteId: src, targetSuiteId: dst, testCase: srcCases.first);
      expect(await repo.getTestCases(src), isEmpty);
      expect(await repo.getTestCases(dst), hasLength(1));
    });

    test('updateSingleCase updates a case', () async {
      final id = await useCase.createSuite(module: 'M', feature: 'F', platform: 'Web');
      await useCase.addCase(suiteId: id, testCase: makeCase(id: 'TC-U', title: 'Original'));
      final cases = await repo.getTestCases(id);
      await useCase.updateSingleCase(suiteId: id, testCase: cases.first.copyWith(title: 'Updated'));
      final after = await repo.getTestCases(id);
      expect(after.first.title, 'Updated');
    });
  });
}
