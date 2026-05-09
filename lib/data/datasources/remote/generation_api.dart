import 'package:qa_app/core/network/api_client.dart';
import 'package:qa_app/data/models/test_case_model.dart';

class GenerationApi {
  final ApiClient _client = ApiClient();

  Future<List<TestCaseModel>> generate(String prompt) async {
    return _client.generate(prompt);
  }
}
