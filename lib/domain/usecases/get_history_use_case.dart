import 'package:qa_genie/data/repositories/suite_repository.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

class GetHistoryUseCase {
  final SuiteRepository _repository;

  const GetHistoryUseCase({required SuiteRepository repository})
    : _repository = repository;

  Future<List<Map<String, dynamic>>> getAllSuites() async {
    return _repository.getAllSuites();
  }

  Future<List<FinalizedTestCase>> getTestCases(int suiteId) async {
    return _repository.getTestCases(suiteId);
  }

  Future<void> deleteSuite(int suiteId) async {
    await _repository.deleteSuite(suiteId);
  }
}
