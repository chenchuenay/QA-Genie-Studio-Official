import 'package:qa_genie/engine/models/pipeline_models.dart';

class CoverageContractValidator {
  static bool satisfiesCategoryCoverage(
    List<WorkingCase> cases,
    List<Map<String, dynamic>> plannedSkeletons,
  ) {
    final required = <String, int>{};
    for (final sk in plannedSkeletons) {
      final cat = sk['category'] as String;
      required[cat] = (required[cat] ?? 0) + 1;
    }
    final actual = <String, int>{};
    for (final wc in cases) {
      actual[wc.categoryLock] = (actual[wc.categoryLock] ?? 0) + 1;
    }
    for (final entry in required.entries) {
      if ((actual[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  static bool satisfiesIntentCoverage(
    List<WorkingCase> cases,
    List<Map<String, dynamic>> plannedSkeletons,
  ) {
    final requiredIntents = plannedSkeletons.map((sk) => sk['intent_id'] as String).toSet();
    final presentIntents = cases.map((wc) => wc.intentId).toSet();
    return requiredIntents.difference(presentIntents).isEmpty;
  }
}