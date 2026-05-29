import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/services/generation_metrics.dart';

@Deprecated('Use PipelineOrchestrator instead')
class GenerationService {
  const GenerationService();

  Future<GenerationResult> generate({
    required String module,
    required String feature,
    required String platform,
    required dynamic mode,
    required int count,
    required Future<String> Function(String prompt) aiExecutor,
    String domain = 'general',
  }) async {
    throw UnimplementedError(
      'GenerationService is deprecated. Use GenerateTestCasesUseCase.',
    );
  }
}

@Deprecated('Use PipelineOrchestrator instead')
class GenerationResult {
  final List<TestCaseModel> cases;
  final GenerationMetrics metrics;
  final PipelineAuditReport auditReport;
  final String traceId;

  const GenerationResult({
    required this.cases,
    required this.metrics,
    required this.auditReport,
    required this.traceId,
  });
}
