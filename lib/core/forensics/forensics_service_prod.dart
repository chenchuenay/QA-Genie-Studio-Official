import 'package:qa_genie/core/forensics/forensics_service.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';

class ForensicsServiceProd implements ForensicsService {
  @override
  void log(String message) {
    // Production: Completely stripped - No-Op
  }

  @override
  Future<void> saveSnapshot({
    required GenerationSession session,
    required PipelineAuditReport auditReport,
    required String rawAiResponse,
    Map<String, dynamic> forensicsContext = const {},
  }) async {
    // Production: Completely stripped - No-Op
  }
}
