import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/recovery/ai_repair_engine.dart';

class RepairStage {
  final AiRepairEngine _repairEngine;

  const RepairStage({required AiRepairEngine repairEngine})
    : _repairEngine = repairEngine;

  List<WorkingCase> execute({
    required List<WorkingCase> cases,
    required int targetCount,
  }) {
    return _repairEngine.repair(cases, targetCount);
  }
}
