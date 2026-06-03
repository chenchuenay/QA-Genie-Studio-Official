import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/scenario/scenario_rules.dart';
import 'package:qa_genie/engine/humanization/qa_heuristics_engine.dart';

/// Repairs AI-generated test cases without creating fallback cases.
class AiRepairEngine {
  const AiRepairEngine();

  List<WorkingCase> repair(List<WorkingCase> cases, int targetCount) {
    final repaired = <WorkingCase>[];
    for (final wc in cases) {
      if (_hasWeakTitle(wc.title) && wc.intentId != '__unknown__') {
        wc.title = _titleForOutcome(wc.intentId, wc.feature);
      }
      if (QaHeuristicsEngine.hasWeakExpectedResult(wc.expectedResult) &&
          wc.intentId != '__unknown__') {
        wc.expectedResult = _expectedResultForOutcome(wc.intentId, wc.platform);
      }
      repaired.add(wc);
    }
    return repaired.take(targetCount).toList();
  }

  bool _hasWeakTitle(String title) {
    final normalized = title.trim().toLowerCase();
    if (normalized.length < 8) return true;
    const weakFragments = [
      'test case',
      'fallback test',
      'sample',
      'dummy',
      'lorem ipsum',
    ];
    return weakFragments.any(normalized.contains);
  }

  String _titleForOutcome(String outcome, String feature) {
    return '${ScenarioRules.describeOutcome(outcome)} test for $feature';
  }

  String _expectedResultForOutcome(String outcome, String platform) {
    if (platform.toUpperCase() == 'API') {
      if (outcome.contains('valid') || outcome.contains('success')) {
        return 'API returns 200 OK with expected data.';
      } else {
        return 'API returns error status with appropriate message.';
      }
    } else {
      if (outcome.contains('valid') || outcome.contains('success')) {
        return 'User successfully completes the action and sees confirmation.';
      } else {
        return 'Error message displayed, action blocked.';
      }
    }
  }
}
