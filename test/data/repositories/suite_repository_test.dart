import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/data/datasources/local/local_db_source.dart';
import 'package:qa_genie/data/repositories/suite_repository.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';

class MockLocalDbSource extends LocalDbSource {
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
  Future<List<Map<String, dynamic>>> getAllSuites() async {
    return _suites.values.toList();
  }

  @override
  Future<void> deleteSuite(int suiteId) async {
    _suites.remove(suiteId);
    _cases.remove(suiteId);
  }

  @override
  Future<List<FinalizedTestCase>> getTestCasesForSuite(int suiteId) async {
    return _cases[suiteId] ?? [];
  }

  @override
  Future<void> insertTestCases({required int suiteId, required List<FinalizedTestCase> cases}) async {
    _cases[suiteId] ??= [];
    for (final tc in cases) {
      final cloned = tc.copyWith(dbId: _nextId++);
      _cases[suiteId]!.add(cloned);
    }
  }

  @override
  Future<void> updateSuiteCases({required int suiteId, required List<FinalizedTestCase> cases}) async {
    _cases[suiteId] = [];
    for (final tc in cases) {
      final cloned = tc.copyWith(dbId: _nextId++);
      _cases[suiteId]!.add(cloned);
    }
  }

  @override
  Future<void> insertSingleCase({required int suiteId, required FinalizedTestCase testCase}) async {
    _cases[suiteId] ??= [];
    final cloned = testCase.copyWith(dbId: _nextId++);
    _cases[suiteId]!.add(cloned);
  }

  @override
  Future<void> deleteTestCase(int dbId) async {
    for (final suiteId in _cases.keys) {
      _cases[suiteId]!.removeWhere((tc) => tc.dbId == dbId);
    }
  }

  @override
  Future<void> copyTestCase({required int targetSuiteId, required FinalizedTestCase testCase}) async {
    final cloned = testCase.copyWith(dbId: _nextId++);
    _cases[targetSuiteId] ??= [];
    _cases[targetSuiteId]!.add(cloned);
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
    if (index != -1) {
      cases[index] = updatedCase;
    }
  }
}

FinalizedTestCase makeCase({String id = 'TC-001', String title = 'Test case', String? dbId}) {
  return FinalizedTestCase(
    dbId: dbId != null ? int.tryParse(dbId) : null,
    id: id,
    title: title,
    preconditions: [],
    testData: '',
    steps: [TestStep(action: 'Step 1', data: '', expected: 'OK')],
    expectedResult: 'Expected result',
    priority: 'Medium',
    type: 'positive',
    module: 'Auth',
    feature: 'Login',
    platform: 'Web',
    source: CaseSource.ai,
  );
}

void main() {
  late SuiteRepository repo;
  late MockLocalDbSource mock;

  setUp(() {
    mock = MockLocalDbSource();
    repo = SuiteRepository(local: mock);
  });

  group('SuiteRepository', () {
    test('createSuite delegates and returns id', () async {
      final id = await repo.createSuite(moduleName: 'Auth', feature: 'Login', platform: 'Web');
      expect(id, greaterThan(0));
    });

    test('getAllSuites returns list of suites', () async {
      await repo.createSuite(moduleName: 'M1', feature: 'F1', platform: 'Web');
      await repo.createSuite(moduleName: 'M2', feature: 'F2', platform: 'iOS');
      final suites = await repo.getAllSuites();
      expect(suites.length, 2);
    });

    test('deleteSuite removes suite', () async {
      final id = await repo.createSuite(moduleName: 'Del', feature: 'Test', platform: 'Web');
      await repo.deleteSuite(id);
      final suites = await repo.getAllSuites();
      expect(suites.where((s) => s['id'] == id), isEmpty);
    });

    test('syncSession updates suite cases', () async {
      final id = await repo.createSuite(moduleName: 'Sync', feature: 'Test', platform: 'Web');
      final session = GenerationSession(
        traceId: 'trace-1',
        testCases: [makeCase(id: 'TC-001', title: 'Synced case')],
        auditReport: const PipelineAuditReport(traceId: 'trace-1'),
      );
      await repo.syncSession(suiteId: id, session: session);
      final cases = await repo.getTestCases(id);
      expect(cases.length, 1);
      expect(cases.first.title, 'Synced case');
    });

    test('saveCases replaces all cases', () async {
      final id = await repo.createSuite(moduleName: 'Save', feature: 'Test', platform: 'Web');
      await repo.saveCases(suiteId: id, cases: [makeCase(id: 'TC-01', title: 'First')]);
      await repo.saveCases(suiteId: id, cases: [makeCase(id: 'TC-02', title: 'Second')]);
      final cases = await repo.getTestCases(id);
      expect(cases.length, 1);
      expect(cases.first.title, 'Second');
    });

    test('addCase appends single case', () async {
      final id = await repo.createSuite(moduleName: 'Add', feature: 'Test', platform: 'Web');
      await repo.addCase(suiteId: id, testCase: makeCase(id: 'TC-01'));
      await repo.addCase(suiteId: id, testCase: makeCase(id: 'TC-02'));
      final cases = await repo.getTestCases(id);
      expect(cases.length, 2);
    });

    test('deleteTestCase removes case', () async {
      final id = await repo.createSuite(moduleName: 'DelCase', feature: 'Test', platform: 'Web');
      await repo.addCase(suiteId: id, testCase: makeCase(id: 'TC-DEL'));
      final cases = await repo.getTestCases(id);
      expect(cases.length, 1);
      if (cases.first.dbId != null) {
        await repo.deleteTestCase(cases.first.dbId!);
      }
      final after = await repo.getTestCases(id);
      expect(after, isEmpty);
    });

    test('copyTestCase copies case to target suite', () async {
      final src = await repo.createSuite(moduleName: 'Src', feature: 'Test', platform: 'Web');
      final dst = await repo.createSuite(moduleName: 'Dst', feature: 'Test', platform: 'Web');
      await repo.addCase(suiteId: src, testCase: makeCase(id: 'TC-CP'));
      final srcCases = await repo.getTestCases(src);
      await repo.copyTestCase(targetSuiteId: dst, testCase: srcCases.first);
      final dstCases = await repo.getTestCases(dst);
      expect(dstCases.length, 1);
      expect(dstCases.first.title, 'Test case');
    });

    test('moveTestCase moves case between suites', () async {
      final src = await repo.createSuite(moduleName: 'SrcM', feature: 'Test', platform: 'Web');
      final dst = await repo.createSuite(moduleName: 'DstM', feature: 'Test', platform: 'Web');
      await repo.addCase(suiteId: src, testCase: makeCase(id: 'TC-MV'));
      final srcCases = await repo.getTestCases(src);
      await repo.moveTestCase(sourceSuiteId: src, targetSuiteId: dst, testCase: srcCases.first);
      final srcAfter = await repo.getTestCases(src);
      final dstAfter = await repo.getTestCases(dst);
      expect(srcAfter, isEmpty);
      expect(dstAfter.length, 1);
    });

    test('updateSingleCase updates case in place', () async {
      final id = await repo.createSuite(moduleName: 'Upd', feature: 'Test', platform: 'Web');
      await repo.addCase(suiteId: id, testCase: makeCase(id: 'TC-UPD', title: 'Original'));
      final cases = await repo.getTestCases(id);
      final updated = cases.first.copyWith(title: 'Updated');
      await repo.updateSingleCase(suiteId: id, testCase: updated);
      final after = await repo.getTestCases(id);
      expect(after.first.title, 'Updated');
    });
  });
}
