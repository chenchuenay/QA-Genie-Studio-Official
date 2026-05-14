import 'package:qa_genie/data/models/test_case_model.dart';

class GenerationResult {
  final List<TestCaseModel> cases;
  final String? warning;

  const GenerationResult({
    required this.cases,
    this.warning,
  });
}
