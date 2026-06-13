import 'package:qa_genie/engine/models/pipeline_models.dart';

class AiRepairEngine {
  List<WorkingCase> repair(List<WorkingCase> cases, int targetCount) {
    // ✅ No mutation – just return original cases.
    // Missing cases will be filled by fallback engine.
    return cases;
  }
}
