import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/data/datasources/local/local_db_source.dart';

class SuiteRepository {
  final LocalDbSource _local;

  const SuiteRepository({required LocalDbSource local}) : _local = local;

  Future<int> createSuite({
    required String moduleName,
    required String feature,
    required String platform,
  }) async {
    return _local.createSuite(
      moduleName: moduleName,
      feature: feature,
      platform: platform,
    );
  }

  Future<List<Map<String, dynamic>>> getAllSuites() async {
    return _local.getAllSuites();
  }

  Future<List<Map<String, dynamic>>> getSuitesPage(int limit, {String? beforeCreatedAt}) async {
    return _local.getSuitesPage(limit, beforeCreatedAt: beforeCreatedAt);
  }

  Future<void> deleteSuite(int suiteId) async {
    await _local.deleteSuite(suiteId);
  }

  Future<void> syncSession({
    required int suiteId,
    required GenerationSession session,
  }) async {
    await _local.updateSuiteCases(suiteId: suiteId, cases: session.testCases);
  }

  Future<List<FinalizedTestCase>> getTestCases(int suiteId) async {
    return _local.getTestCasesForSuite(suiteId);
  }

  Future<void> saveCases({
    required int suiteId,
    required List<FinalizedTestCase> cases,
  }) async {
    await _local.updateSuiteCases(suiteId: suiteId, cases: cases);
  }

  Future<void> addCase({
    required int suiteId,
    required FinalizedTestCase testCase,
  }) async {
    await _local.insertSingleCase(suiteId: suiteId, testCase: testCase);
  }

  Future<void> deleteTestCase(int dbId) async {
    await _local.deleteTestCase(dbId);
  }

  Future<void> copyTestCase({
    required int targetSuiteId,
    required FinalizedTestCase testCase,
  }) async {
    await _local.copyTestCase(targetSuiteId: targetSuiteId, testCase: testCase);
  }

  Future<void> moveTestCase({
    required int sourceSuiteId,
    required int targetSuiteId,
    required FinalizedTestCase testCase,
  }) async {
    await _local.moveTestCase(
      sourceSuiteId: sourceSuiteId,
      targetSuiteId: targetSuiteId,
      testCase: testCase,
    );
  }

  Future<void> updateSingleCase({
    required int suiteId,
    required FinalizedTestCase testCase,
  }) async {
    await _local.replaceSingleCase(suiteId: suiteId, updatedCase: testCase);
  }
}
