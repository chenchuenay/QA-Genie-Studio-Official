import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

class LocalDbSource {
  const LocalDbSource();

  Future<int> createSuite({required String moduleName, required String feature, required String platform}) async =>
    DatabaseService.insertSuite(moduleName: moduleName, feature: feature, platform: platform);

  Future<List<Map<String, dynamic>>> getAllSuites() async => DatabaseService.getAllSuites();

  Future<List<Map<String, dynamic>>> getSuitesPage(int limit, {String? beforeCreatedAt}) async =>
    DatabaseService.getSuitesPage(limit, beforeCreatedAt: beforeCreatedAt);

  Future<void> deleteSuite(int suiteId) async => DatabaseService.deleteSuite(suiteId);

  Future<List<FinalizedTestCase>> getTestCasesForSuite(int suiteId) async => DatabaseService.getTestCasesForSuite(suiteId);

  Future<void> insertTestCases({required int suiteId, required List<FinalizedTestCase> cases}) async =>
    DatabaseService.insertTestCases(suiteId: suiteId, cases: cases);

  Future<void> updateSuiteCases({required int suiteId, required List<FinalizedTestCase> cases}) async {
    await DatabaseService.replaceAllTestCases(suiteId: suiteId, cases: cases);
    await DatabaseService.markSuiteDirty(suiteId);
  }

  Future<void> insertSingleCase({required int suiteId, required FinalizedTestCase testCase}) async {
    await DatabaseService.insertTestCases(suiteId: suiteId, cases: [testCase]);
    await DatabaseService.markSuiteDirty(suiteId);
  }

  Future<void> deleteTestCase(int dbId) async => DatabaseService.deleteTestCase(dbId);

  Future<void> copyTestCase({required int targetSuiteId, required FinalizedTestCase testCase}) async {
    final cloned = testCase.copyWith(dbId: null);
    await DatabaseService.insertTestCases(suiteId: targetSuiteId, cases: [cloned]);
    await DatabaseService.markSuiteDirty(targetSuiteId);
  }

  Future<void> moveTestCase({required int sourceSuiteId, required int targetSuiteId, required FinalizedTestCase testCase}) async {
    await copyTestCase(targetSuiteId: targetSuiteId, testCase: testCase);
    if (testCase.dbId != null) await DatabaseService.deleteTestCase(testCase.dbId!);
    await DatabaseService.markSuiteDirty(sourceSuiteId);
  }

  Future<void> replaceSingleCase({required int suiteId, required FinalizedTestCase updatedCase}) async {
    if (updatedCase.dbId != null) {
      await DatabaseService.updateSingleCase(dbId: updatedCase.dbId!, tc: updatedCase);
      await DatabaseService.markSuiteDirty(suiteId);
    }
  }
}