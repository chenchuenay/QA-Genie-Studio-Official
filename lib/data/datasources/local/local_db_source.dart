import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

class LocalDbSource {
  const LocalDbSource();

  // Suites
  Future<int> createSuite({
    required String moduleName,
    required String feature,
    required String platform,
  }) async {
    return DatabaseService.insertSuite(
      moduleName: moduleName,
      feature: feature,
      platform: platform,
    );
  }

  Future<List<Map<String, dynamic>>> getAllSuites() async {
    return DatabaseService.getAllSuites();
  }

  Future<void> deleteSuite(int suiteId) async {
    await DatabaseService.deleteSuite(suiteId);
  }

  // Test Cases – now using FinalizedTestCase
  Future<List<FinalizedTestCase>> getTestCasesForSuite(int suiteId) async {
    return DatabaseService.getTestCasesForSuite(suiteId);
  }

  Future<void> insertTestCases({
    required int suiteId,
    required List<FinalizedTestCase> cases,
  }) async {
    await DatabaseService.insertTestCases(suiteId: suiteId, cases: cases);
  }

  Future<void> updateSuiteCases({
    required int suiteId,
    required List<FinalizedTestCase> cases,
  }) async {
    // Replace all test cases for the suite
    final existing = await DatabaseService.getTestCasesForSuite(suiteId);
    for (final tc in existing) {
      if (tc.dbId != null) await DatabaseService.deleteTestCase(tc.dbId!);
    }
    await DatabaseService.insertTestCases(suiteId: suiteId, cases: cases);
  }

  Future<void> insertSingleCase({
    required int suiteId,
    required FinalizedTestCase testCase,
  }) async {
    await DatabaseService.insertTestCases(suiteId: suiteId, cases: [testCase]);
  }

  Future<void> deleteTestCase(int dbId) async {
    await DatabaseService.deleteTestCase(dbId);
  }

  Future<void> copyTestCase({
    required int targetSuiteId,
    required FinalizedTestCase testCase,
  }) async {
    final cloned = testCase.copyWith(dbId: null);
    await DatabaseService.insertTestCases(
      suiteId: targetSuiteId,
      cases: [cloned],
    );
  }

  Future<void> moveTestCase({
    required int sourceSuiteId,
    required int targetSuiteId,
    required FinalizedTestCase testCase,
  }) async {
    await copyTestCase(targetSuiteId: targetSuiteId, testCase: testCase);
    if (testCase.dbId != null)
      await DatabaseService.deleteTestCase(testCase.dbId!);
  }

  Future<void> replaceSingleCase({
    required int suiteId,
    required FinalizedTestCase updatedCase,
  }) async {
    final allCases = await DatabaseService.getTestCasesForSuite(suiteId);
    final updated = allCases.map((tc) {
      return tc.dbId == updatedCase.dbId ? updatedCase : tc;
    }).toList();
    await updateSuiteCases(suiteId: suiteId, cases: updated);
  }
}
