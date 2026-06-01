import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/business/business_area.dart';
import 'package:qa_genie/engine/scenario/scenario_rules.dart';
import 'package:qa_genie/engine/humanization/qa_heuristics_engine.dart';

/// Repairs AI‑generated test cases without using IntentRegistry.
class AiRepairEngine {
  const AiRepairEngine();

  List<WorkingCase> repair(List<WorkingCase> cases, int targetCount) {
    final repaired = <WorkingCase>[];
    for (final wc in cases) {
      // Simple title repair based on outcome (intentId)
      if (QaHeuristicsEngine.hasWeakExpectedResult(wc.title) &&
          wc.intentId != '__unknown__') {
        wc.title = _titleForOutcome(wc.intentId, wc.feature);
      }
      // Expected result repair using heuristics
      if (QaHeuristicsEngine.hasWeakExpectedResult(wc.expectedResult) &&
          wc.intentId != '__unknown__') {
        wc.expectedResult = _expectedResultForOutcome(wc.intentId, wc.platform);
      }
      repaired.add(wc);
    }
    while (repaired.length < targetCount) {
      repaired.add(_createFallbackCase());
    }
    return repaired.take(targetCount).toList();
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

  WorkingCase _createFallbackCase() {
    return WorkingCase(
      id: 'temp',
      title: 'Fallback test case',
      module: 'unknown',
      feature: 'unknown',
      platform: 'Web',
      priority: 'Medium',
      type: 'GENERAL',
      categoryLock: 'positive',
      preconditions: [],
      testData: '',
      steps: [],
      expectedResult: '',
      actualResult: '',
      status: 'Not Executed',
      metadata: CaseMetadata(
        source: CaseSource.fallback,
        traceId: '',
        intentId: 'fallback_generic',
      ),
      intentId: 'fallback_generic',
    );
  }
}
