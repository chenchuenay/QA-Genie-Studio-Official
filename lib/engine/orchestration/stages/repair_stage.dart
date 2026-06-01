import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/recovery/repair_engine.dart';

class RepairStage {
  final RepairEngine _repairEngine;

  const RepairStage({required RepairEngine repairEngine}) : _repairEngine = repairEngine;

  List<WorkingCase> execute({required List<WorkingCase> cases, required int targetCount}) {
    return _repairEngine.repair(cases, targetCount);
  }
}