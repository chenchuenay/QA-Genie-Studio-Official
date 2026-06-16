import 'package:flutter/foundation.dart' show debugPrint;
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/data/repositories/suite_repository.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

class SaveSuiteUseCase {
  final SuiteRepository _repository;

  const SaveSuiteUseCase({required SuiteRepository repository})
    : _repository = repository;

  Future<int> createSuite({
    required String module,
    required String feature,
    required String platform,
  }) async {
    debugPrint('💾 SaveSuiteUseCase: createSuite $module $feature');
    final id = await _repository.createSuite(
      moduleName: module,
      feature: feature,
      platform: platform,
    );
    debugPrint('💾 SaveSuiteUseCase: created suite ID $id');
    return id;
  }

  Future<void> syncSession({
    required int suiteId,
    required GenerationSession session,
  }) async {
    await _repository.syncSession(suiteId: suiteId, session: session);
  }

  // Canonical API – use these
  Future<void> saveSuite({
    required int suiteId,
    required List<FinalizedTestCase> cases,
  }) async {
    debugPrint('💾 SaveSuiteUseCase: saveSuite $suiteId with ${cases.length} cases');
    await _repository.saveCases(suiteId: suiteId, cases: cases);
    debugPrint('💾 SaveSuiteUseCase: saveSuite complete');
  }

  Future<void> update({
    required int suiteId,
    required List<FinalizedTestCase> cases,
  }) async {
    await _repository.saveCases(suiteId: suiteId, cases: cases);
  }

  Future<void> updateSingleCase({
    required int suiteId,
    required FinalizedTestCase testCase,
  }) async {
    await _repository.updateSingleCase(suiteId: suiteId, testCase: testCase);
  }

  Future<void> addCase({
    required int suiteId,
    required FinalizedTestCase testCase,
  }) async {
    await _repository.addCase(suiteId: suiteId, testCase: testCase);
  }

  Future<void> deleteCase(int dbId) async {
    await _repository.deleteTestCase(dbId);
  }

  Future<void> copyCase({
    required int targetSuiteId,
    required FinalizedTestCase testCase,
  }) async {
    await _repository.copyTestCase(
      targetSuiteId: targetSuiteId,
      testCase: testCase,
    );
  }

  Future<void> moveCase({
    required int sourceSuiteId,
    required int targetSuiteId,
    required FinalizedTestCase testCase,
  }) async {
    await _repository.moveTestCase(
      sourceSuiteId: sourceSuiteId,
      targetSuiteId: targetSuiteId,
      testCase: testCase,
    );
  }
}
