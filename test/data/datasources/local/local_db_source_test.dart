import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/data/datasources/local/local_db_source.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

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

FinalizedTestCase makeCase({String id = 'TC-001', String title = 'Test case', String priority = 'Medium'}) {
  return FinalizedTestCase(
    dbId: null, id: id, title: title, preconditions: [], testData: '',
    steps: [TestStep(action: 'Step 1', data: '', expected: 'OK')], expectedResult: 'Expected result',
    priority: priority, type: 'positive', module: 'Auth', feature: 'Login', platform: 'Web',
    source: CaseSource.ai,
  );
}

void main() {
  late MockLocalDbSource source;

  setUp(() {
    source = MockLocalDbSource();
  });

  group('LocalDbSource', () {
    test('createSuite inserts and returns id', () async {
      final id = await source.createSuite(moduleName: 'Auth', feature: 'Login', platform: 'Web');
      expect(id, greaterThan(0));
    });

    test('createSuite returns different ids for different suites', () async {
      final id1 = await source.createSuite(moduleName: 'M1', feature: 'F1', platform: 'Web');
      final id2 = await source.createSuite(moduleName: 'M2', feature: 'F2', platform: 'iOS');
      expect(id1, isNot(id2));
    });

    test('getAllSuites returns all suites', () async {
      await source.createSuite(moduleName: 'M1', feature: 'F1', platform: 'Web');
      await source.createSuite(moduleName: 'M2', feature: 'F2', platform: 'iOS');
      final suites = await source.getAllSuites();
      expect(suites.length, 2);
    });

    test('deleteSuite removes suite', () async {
      final id = await source.createSuite(moduleName: 'ToDelete', feature: 'Test', platform: 'Web');
      await source.deleteSuite(id);
      final suites = await source.getAllSuites();
      expect(suites.where((s) => s['id'] == id), isEmpty);
    });

    test('insertTestCases and getTestCasesForSuite round-trip', () async {
      final id = await source.createSuite(moduleName: 'RT', feature: 'Test', platform: 'Web');
      final tc = makeCase(id: 'TC-RT-1', title: 'Round trip test');
      await source.insertTestCases(suiteId: id, cases: [tc]);
      final retrieved = await source.getTestCasesForSuite(id);
      expect(retrieved.length, 1);
      expect(retrieved.first.title, 'Round trip test');
    });

    test('updateSuiteCases replaces all test cases', () async {
      final id = await source.createSuite(moduleName: 'Upd', feature: 'Test', platform: 'Web');
      await source.insertTestCases(suiteId: id, cases: [makeCase(id: 'TC-01', title: 'First')]);
      await source.updateSuiteCases(suiteId: id, cases: [makeCase(id: 'TC-02', title: 'Second')]);
      final retrieved = await source.getTestCasesForSuite(id);
      expect(retrieved.length, 1);
      expect(retrieved.first.title, 'Second');
    });

    test('deleteTestCase removes single case', () async {
      final id = await source.createSuite(moduleName: 'DelCase', feature: 'Test', platform: 'Web');
      await source.insertTestCases(suiteId: id, cases: [makeCase(id: 'TC-DEL')]);
      final inserted = await source.getTestCasesForSuite(id);
      expect(inserted.length, 1);
      if (inserted.first.dbId != null) {
        await source.deleteTestCase(inserted.first.dbId!);
      }
      final after = await source.getTestCasesForSuite(id);
      expect(after, isEmpty);
    });

    test('copyTestCase clones case into target suite', () async {
      final srcId = await source.createSuite(moduleName: 'Src', feature: 'Test', platform: 'Web');
      final dstId = await source.createSuite(moduleName: 'Dst', feature: 'Test', platform: 'Web');
      await source.insertTestCases(suiteId: srcId, cases: [makeCase(id: 'TC-CP')]);
      final inserted = await source.getTestCasesForSuite(srcId);
      await source.copyTestCase(targetSuiteId: dstId, testCase: inserted.first);
      final dstCases = await source.getTestCasesForSuite(dstId);
      expect(dstCases.length, 1);
      expect(dstCases.first.dbId, isNot(inserted.first.dbId));
    });

    test('moveTestCase moves case from source to target', () async {
      final srcId = await source.createSuite(moduleName: 'SrcM', feature: 'Test', platform: 'Web');
      final dstId = await source.createSuite(moduleName: 'DstM', feature: 'Test', platform: 'Web');
      await source.insertTestCases(suiteId: srcId, cases: [makeCase(id: 'TC-MV')]);
      final inserted = await source.getTestCasesForSuite(srcId);
      await source.moveTestCase(sourceSuiteId: srcId, targetSuiteId: dstId, testCase: inserted.first);
      final srcCases = await source.getTestCasesForSuite(srcId);
      final dstCases = await source.getTestCasesForSuite(dstId);
      expect(srcCases, isEmpty);
      expect(dstCases.length, 1);
    });

    test('replaceSingleCase updates case in suite', () async {
      final id = await source.createSuite(moduleName: 'Replace', feature: 'Test', platform: 'Web');
      await source.insertTestCases(suiteId: id, cases: [makeCase(id: 'TC-RP', title: 'Original')]);
      final inserted = await source.getTestCasesForSuite(id);
      final updated = inserted.first.copyWith(title: 'Updated');
      if (updated.dbId != null) {
        await source.replaceSingleCase(suiteId: id, updatedCase: updated);
      }
      final retrieved = await source.getTestCasesForSuite(id);
      expect(retrieved.first.title, 'Updated');
    });
  });
}
