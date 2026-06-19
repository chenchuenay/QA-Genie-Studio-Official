import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/usecases/get_history_use_case.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/data/repositories/suite_repository.dart';
import 'package:qa_genie/data/datasources/local/local_db_source.dart';

class MockLocalDbForHistory extends LocalDbSource {
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
  Future<void> updateSuiteCases({required int suiteId, required List<FinalizedTestCase> cases}) async {
    _cases[suiteId] = [];
    for (final tc in cases) {
      _cases[suiteId]!.add(tc.copyWith(dbId: _nextId++));
    }
  }
}

FinalizedTestCase makeCase({String id = 'TC-001', String title = 'Test'}) {
  return FinalizedTestCase(
    dbId: null, id: id, title: title, preconditions: [], testData: '',
    steps: [TestStep(action: 'A', data: '', expected: 'B')], expectedResult: 'R',
    priority: 'Medium', type: 'positive', module: 'M', feature: 'F', platform: 'Web',
    source: CaseSource.ai,
  );
}

void main() {
  late GetHistoryUseCase useCase;
  late SuiteRepository repo;

  setUp(() {
    repo = SuiteRepository(local: MockLocalDbForHistory());
    useCase = GetHistoryUseCase(repository: repo);
  });

  group('GetHistoryUseCase', () {
    test('getAllSuites returns all suites', () async {
      await repo.createSuite(moduleName: 'M1', feature: 'F1', platform: 'Web');
      await repo.createSuite(moduleName: 'M2', feature: 'F2', platform: 'iOS');
      final suites = await useCase.getAllSuites();
      expect(suites.length, 2);
    });

    test('getAllSuites returns empty list when no suites', () async {
      final suites = await useCase.getAllSuites();
      expect(suites, isEmpty);
    });

    test('getTestCases returns cases for suite', () async {
      final id = await repo.createSuite(moduleName: 'M', feature: 'F', platform: 'Web');
      await repo.saveCases(suiteId: id, cases: [
        makeCase(id: 'TC-1', title: 'Case one'),
        makeCase(id: 'TC-2', title: 'Case two'),
      ]);
      final cases = await useCase.getTestCases(id);
      expect(cases.length, 2);
      expect(cases.map((c) => c.title), containsAll(['Case one', 'Case two']));
    });

    test('getTestCases returns empty list for suite with no cases', () async {
      final id = await repo.createSuite(moduleName: 'M', feature: 'F', platform: 'Web');
      final cases = await useCase.getTestCases(id);
      expect(cases, isEmpty);
    });

    test('deleteSuite removes suite', () async {
      final id = await repo.createSuite(moduleName: 'Del', feature: 'Test', platform: 'Web');
      await useCase.deleteSuite(id);
      final suites = await useCase.getAllSuites();
      expect(suites.where((s) => s['id'] == id), isEmpty);
    });

    test('deleteSuite with non-existent id does not throw', () async {
      await expectLater(useCase.deleteSuite(9999), completes);
    });
  });
}
