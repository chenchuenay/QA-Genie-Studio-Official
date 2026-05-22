import 'package:qa_genie/data/models/test_case_model.dart';

class BehavioralWorkflowIntegrityEvaluator {
  static const List<String> _genericAIPhrases = [
    'system processes input correctly',
    'operation completes successfully',
    'workflow integrity maintained',
    'successful update reflected',
    'ui confirms successful change',
    'verify behavior',
    'system responds accordingly',
  ];

  static int evaluate(List<TestCaseModel> cases, String platform) {
    if (cases.isEmpty) return 0;
    double suiteScore = 0;
    for (final tc in cases) {
      suiteScore += _evaluateCase(tc, platform);
    }
    return (suiteScore / cases.length).toInt().clamp(0, 100);
  }

  static double _evaluateCase(TestCaseModel tc, String platform) {
    double score = 20.0; // Base score

    final expected = tc.expectedResult.toLowerCase();
    final steps = tc.steps;
    final allText = '${tc.title} ${tc.expectedResult} ${steps.map((s) => '${s.action} ${s.expected}').join(' ')}'.toLowerCase();

    // 1. Workflow State Transition Integrity
    // Check for Action -> Resulting State causality in steps
    int transitionCount = 0;
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final action = step.action.toLowerCase();
      final outcome = step.expected.toLowerCase();
      
      // Look for behavioral markers of state transition
      if ((action.contains('from') || action.contains('after') || action.contains('during')) &&
          (outcome.contains('resulting') || outcome.contains('state') || outcome.contains('status'))) {
        transitionCount++;
      }
    }
    score += (transitionCount * 10.0);

    // 2. Behavioral Causality (Interruption -> Recovery -> Observable Consequence)
    bool hasBehavioralChain = false;
    if (platform == 'Web') {
      if (allText.contains('refresh') && (allText.contains('persist') || allText.contains('visible') || allText.contains('remain'))) {
        hasBehavioralChain = true;
      }
    } else if (platform == 'Mobile') {
      if ((allText.contains('background') || allText.contains('reopen')) && (allText.contains('resume') || allText.contains('restore') || allText.contains('available'))) {
        hasBehavioralChain = true;
      }
    } else if (platform == 'API') {
      if (allText.contains('retry') && (allText.contains('idempotent') || allText.contains('duplicate') || allText.contains('integrity'))) {
        hasBehavioralChain = true;
      }
    }
    if (hasBehavioralChain) score += 20.0;

    // 3. Observable Consequence Specificity
    if (['redirected', 'blocked', 'ignored', 'cleared', 'visible', 'retained', 're-authenticated', 'preserved'].any(expected.contains)) {
      score += 20.0;
    }

    // 4. Platform Lifecycle Realism
    bool hasPlatformBehavior = false;
    if (platform == 'Web' && (allText.contains('browser refresh') || allText.contains('tab continuity') || allText.contains('navigation history'))) {
      hasPlatformBehavior = true;
    } else if (platform == 'Mobile' && (allText.contains('app background') || allText.contains('lifecycle') || allText.contains('connectivity restore'))) {
      hasPlatformBehavior = true;
    } else if (platform == 'API' && (allText.contains('idempotent') || allText.contains('retry safety') || allText.contains('duplicate transaction'))) {
      hasPlatformBehavior = true;
    }
    if (hasPlatformBehavior) score += 20.0;

    // 5. Generic Phrase Penalties
    for (final phrase in _genericAIPhrases) {
      if (allText.contains(phrase)) {
        score -= 25.0;
      }
    }

    return score.clamp(0.0, 100.0);
  }
}
