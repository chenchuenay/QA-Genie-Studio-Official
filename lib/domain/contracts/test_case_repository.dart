import '../entities/test_case.dart';
abstract class ITestCaseRepository {
  Future<List<TestCase>> generateTestCases(String prompt);
  Future<List<TestCase>> getSuite(int suiteId);
}
