import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/knowledge/intent_registry.dart';
import 'package:qa_genie/engine/humanization/qa_heuristics_engine.dart';
import 'package:qa_genie/domain/enums/case_source.dart';  // ADD THIS LINE

class RepairEngine {
  const RepairEngine();

  List<WorkingCase> repair(List<WorkingCase> cases, int targetCount) {
    final repaired = <WorkingCase>[];

    for (final wc in cases) {
      // Intent-aware title repair
      if (QaHeuristicsEngine.hasWeakExpectedResult(wc.title) && wc.intentId != '__unknown__') {
        final intent = IntentRegistry.get(wc.intentId);
        if (intent != null) {
          wc.title = _titleForIntent(intent);
        }
      }
      // Intent-aware expected result repair
      if (QaHeuristicsEngine.hasWeakExpectedResult(wc.expectedResult) && wc.intentId != '__unknown__') {
        final intent = IntentRegistry.get(wc.intentId);
        if (intent != null) {
          wc.expectedResult = intent.expectedOutcome;
        }
      }
      repaired.add(wc);
    }

    while (repaired.length < targetCount) {
      repaired.add(_createFallbackCase());
    }
    return repaired.take(targetCount).toList();
  }

  String _titleForIntent(IntentDefinition intent) {
    switch (intent.id) {
      case 'valid_authentication':
        return 'User logs in with valid credentials';
      case 'invalid_credential':
        return 'Login fails with invalid password';
      case 'empty_email':
        return 'Email field validation – empty input rejected';
      case 'sql_injection':
        return 'SQL injection attempt blocked in login form';
      case 'session_expiry':
        return 'Session expires after inactivity';
      default:
        return '${intent.category} flow: ${intent.id}';
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