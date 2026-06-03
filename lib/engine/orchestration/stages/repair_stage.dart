import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/recovery/ai_repair_engine.dart';

class RepairStage {
  final AiRepairEngine _repairEngine;

  const RepairStage({required AiRepairEngine repairEngine})
    : _repairEngine = repairEngine;

  RepairStageResult execute({
    required List<WorkingCase> cases,
    required int targetCount,
  }) {
    final before = cases.map((e) => e.copy()).toList();
    final repaired = _repairEngine.repair(cases, targetCount);
    final repairLog = <String>[];

    for (int i = 0; i < repaired.length && i < before.length; i++) {
      final original = before[i];
      final current = repaired[i];
      final operations = <String>[];
      if (original.title != current.title) operations.add('title');
      if (original.expectedResult != current.expectedResult) {
        operations.add('expectedResult');
      }
      if (operations.isNotEmpty) {
        repairLog.add('${current.id}: ${operations.join(', ')}');
      }
    }

    return RepairStageResult(cases: repaired, repairLog: repairLog);
  }
}

class RepairStageResult {
  final List<WorkingCase> cases;
  final List<String> repairLog;

  const RepairStageResult({required this.cases, required this.repairLog});

  int get repairedCount => repairLog.length;
}
