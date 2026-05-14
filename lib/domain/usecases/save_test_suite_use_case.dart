import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
class SaveTestSuiteUseCase {
  Future<int> execute({required String module, required String feature, required String platform, required List<TestCaseModel> cases}) async {
    final id = await DatabaseService.insertSuite(module, feature, platform);
    await DatabaseService.insertTestCases(id, cases);
    return id;
  }
  Future<void> update({required int suiteId, required List<TestCaseModel> cases}) async {
    await DatabaseService.updateSuiteTestCases(suiteId, cases);
  }
}
