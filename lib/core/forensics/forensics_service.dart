import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/forensics/error_capture_utils.dart';

abstract class ForensicsService {
  void log(String message);
  Future<void> saveSnapshot({
    required GenerationSession session,
    required PipelineAuditReport auditReport,
    required String rawAiResponse,
    Map<String, dynamic> forensicsContext = const {},
  });
}
