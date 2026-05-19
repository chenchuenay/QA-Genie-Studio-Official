import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/pipeline/generation_context.dart';
import 'package:qa_genie/engine/pipeline/semantic_validator.dart';
import 'package:qa_genie/engine/pipeline/deduplication_engine.dart';
import 'package:qa_genie/engine/pipeline/structural_validator.dart';
import 'package:qa_genie/engine/pipeline/quality_scoring_engine.dart';
import 'package:qa_genie/engine/pipeline/export_safety_validator.dart';

class EmergencyRecoveryEngine {
  List<WorkingCase> recover(
    GenerationContext context,
    List<WorkingCase> currentCases,
    int maxCases,
  ) {
    final recovered = <WorkingCase>[];
    final quality = QualityScoringEngine();
    final exportValidator = ExportSafetyValidator();
    final semanticValidator = SemanticValidator();
    final structuralValidator = StructuralValidator();
    final deduper = DeduplicationEngine();

    var attempt = 0;
    while (recovered.length + currentCases.length < maxCases &&
        attempt < context.config.maxRecoveryAttempts) {
      if (context.isTimedOut) break;
      attempt += 1;

      final emergency = _buildEmergencyWorkingCase(
        context,
        currentCases.length + recovered.length + 1,
      );

      // Emergency cases MUST pass all deterministic gates
      final structural = structuralValidator.validate(context, [emergency]);
      if (structural.validCases.isEmpty) continue;

      final semantic = semanticValidator.validate(
        context,
        structural.validCases,
      );
      if (semantic.validCases.isEmpty) continue;

      final confidence = quality.calculateConfidence(
        semantic.validCases.single,
      );
      if (confidence < 0.6) continue;

      if (!exportValidator.validate([
        semantic.validCases.single,
      ]).isSuccessful) {
        continue;
      }

      final dedupResult = deduper.deduplicate(context, [
        ...currentCases,
        ...recovered,
        semantic.validCases.single,
      ]);

      if (dedupResult.cases.length ==
          currentCases.length + recovered.length + 1) {
        recovered.add(semantic.validCases.single);
      }
    }

    return recovered;
  }

  WorkingCase _buildEmergencyWorkingCase(GenerationContext context, int index) {
    final scenario = _getEmergencyScenario(index, context.feature);
    return WorkingCase(
      id: 'EMG-$index',
      title: 'Verify ${context.feature}: ${scenario.title}',
      module: context.module,
      feature: context.feature,
      platform: context.platform,
      preconditions: ['The ${context.feature} module is active.'],
      steps: scenario.steps,
      expectedResult: scenario.expected,
      priority: 'Medium',
      type: 'FUNCTIONAL',
      status: 'Draft',
      actualResult: '',
      metadata: CaseMetadata(origin: 'Emergency'),
    );
  }

  static _EmergencyScenario _getEmergencyScenario(int index, String feature) {
    final scenarios = [
      _EmergencyScenario(
        title: 'Happy Path Execution',
        steps: [
          TestStep(
            action: 'Launch $feature feature',
            data: '',
            expected: 'Feature loads successfully.',
          ),
          TestStep(
            action: 'Input standard $feature data',
            data: 'valid_input',
            expected: 'Data is accepted.',
          ),
          TestStep(
            action: 'Submit $feature action',
            data: '',
            expected: 'Action completes without error.',
          ),
        ],
        expected:
            'The core $feature workflow completes under normal conditions.',
      ),
      _EmergencyScenario(
        title: 'Empty State Validation',
        steps: [
          TestStep(
            action: 'Open $feature with no records',
            data: '',
            expected: 'Empty state is displayed.',
          ),
          TestStep(
            action: 'Attempt action on empty $feature',
            data: '',
            expected: 'Graceful warning shown.',
          ),
          TestStep(
            action: 'Verify system stability',
            data: '',
            expected: 'No crash occurred.',
          ),
        ],
        expected:
            'The $feature feature handles empty data scenarios gracefully.',
      ),
    ];
    return scenarios[index % scenarios.length];
  }
}

class _EmergencyScenario {
  final String title;
  final List<TestStep> steps;
  final String expected;
  _EmergencyScenario({
    required this.title,
    required this.steps,
    required this.expected,
  });
}
