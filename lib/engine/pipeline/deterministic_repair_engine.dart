import 'package:qa_genie/engine/pipeline/models/pipeline_models.dart';
import 'package:qa_genie/engine/pipeline/generation_context.dart';
import 'package:qa_genie/engine/pipeline/rules/repair/repair_rule.dart';
import 'package:qa_genie/engine/pipeline/rules/repair/common_rules.dart';

class DeterministicRepairEngine {
  final List<RepairRule> _rules = [
    MissingExpectedResultRule(),
    PlatformViolationRule(),
    GenericPhraseRule(),
  ];

  List<WorkingCase> repair(
    GenerationContext context,
    List<WorkingCase> cases,
  ) {
    // Immutable transition: create copies for the repaired snapshot
    final repairedCases = cases.map((tc) => tc.copy()).toList();

    for (final tc in repairedCases) {
      for (final rule in _rules) {
        if (rule.apply(tc)) {
          context.logRepair('Applied ${rule.name} to "${tc.title}"');
        }
      }
    }

    return repairedCases;
  }
}
