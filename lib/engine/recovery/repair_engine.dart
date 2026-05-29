import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/planners/scenario_planner.dart';
import 'package:qa_genie/engine/recovery/deterministic_repair.dart';

@Deprecated('Legacy migration bridge')
// ============================================================
// lib/engine/recovery/repair_engine.dart
// ============================================================
@Deprecated('Use DeterministicRepair directly')
class RepairEngine {
  final ScenarioPlanner planner;
  late final DeterministicRepair _deterministicRepair;

  RepairEngine({required this.planner}) {
    _deterministicRepair = DeterministicRepair(planner);
  }

  List<WorkingCase> repair(List<WorkingCase> cases, int targetCount) {
    return _deterministicRepair.repair(cases, targetCount);
  }

  List<RepairEvent> get repairEvents => _deterministicRepair.repairEvents;
}

class RepairEvent {
  final String testCaseId;
  final String changedField;
  final String before;
  final String after;
  final String reason;

  const RepairEvent({
    required this.testCaseId,
    required this.changedField,
    required this.before,
    required this.after,
    required this.reason,
  });
}
