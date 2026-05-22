import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/enums/execution_intent.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/engine/humanization/qa_realism_enforcer.dart';

class FallbackGenerator {
  static List<TestCaseModel> generate({
    required int count,
    required String module,
    required String feature,
    required String platform,
  }) {
    final resolvedFeature = feature.trim().isNotEmpty ? feature : module;
    final cases = <TestCaseModel>[];
    final seen = <String>{};

    for (int i = 1; i <= count; i++) {
      final tc = _variantCase(
        module: module,
        feature: resolvedFeature,
        platform: platform,
        variant: i,
      );
      final key = tc.title.toLowerCase().trim();
      if (seen.add(key)) cases.add(tc);
    }

    return cases.take(count).toList();
  }

  static TestCaseModel _variantCase({
    required String module,
    required String feature,
    required String platform,
    required int variant,
  }) {
    final context = '$module $feature';
    final intents = <ExecutionIntent>[
      ExecutionIntent.positive,
      ExecutionIntent.positive,
      ExecutionIntent.positive,
      ExecutionIntent.duplicateProtection, // validation
      ExecutionIntent.retrySafety,       // negative
      ExecutionIntent.usability,
      ExecutionIntent.interruptionRecovery, // edge
    ];
    final intent = intents[variant % intents.length];
    
    final steps = <TestStep>[];
    String baseTitle = 'Verify $feature behavior during ${intent.name}';
    String expected = 'Workflow state is maintained correctly.';

    steps.add(_step('Access $feature workflow', '', 'The $feature interface loads with no data loss.'));
    steps.add(_step('Process data using terms', '', 'Updated values remain visible and workflow continues.'));
    expected = 'Processed results appear without resetting form state.';

    return _case(
      module: module,
      feature: feature,
      platform: platform,
      title: QaRealismEnforcer.humanizeTitle(baseTitle, context),
      type: _intentToType(intent),
      priority: intent == ExecutionIntent.positive
          ? 'Low'
          : 'Medium',
      preconditions: ['Environment configured for $feature testing.'],
      steps: steps,
      expectedResult: QaRealismEnforcer.humanizeExpectedResult(expected, context, intent: intent, platform: platform),
      intent: intent,
    );
  }

  static String _intentToType(ExecutionIntent intent) {
    switch (intent) {
      case ExecutionIntent.sessionIsolation: return 'SECURITY';
      case ExecutionIntent.retrySafety: return 'NETWORK';
      case ExecutionIntent.duplicateProtection: return 'VALIDATION';
      case ExecutionIntent.positive: return 'POSITIVE';
      default: return 'FUNCTIONAL';
    }
  }

  static TestCaseModel _case({
    required String module,
    required String feature,
    required String platform,
    required String title,
    required String type,
    required String priority,
    required List<String> preconditions,
    required List<TestStep> steps,
    required String expectedResult,
    ExecutionIntent? intent,
  }) {
    return TestCaseModel(
      source: CaseSource.fallback,
      title: title,
      module: module,
      feature: feature,
      platform: platform,
      priority: priority,
      type: type,
      preconditions: preconditions,
      steps: steps,
      expectedResult: expectedResult,
      actualResult: '',
      status: 'Not Executed',
      intent: intent,
    );
  }

  static TestStep _step(String action, String data, String expected) {
    return TestStep(action: action, data: data, expected: expected);
  }
}
