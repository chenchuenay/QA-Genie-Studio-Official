import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

class FinalizationStage {
  List<FinalizedTestCase> execute({
    required List<WorkingCase> cases,
    required String module,
  }) {
    final normalizedModule = _normalizeModule(module);
    final finalized = <FinalizedTestCase>[];

    for (int i = 0; i < cases.length; i++) {
      final working = cases[i];
      final canonicalSteps = working.steps.map((step) {
        return TestStep(
          action: step.action,
          data: step.data,
          expected: step.expected,
        );
      }).toList();

      finalized.add(
        FinalizedTestCase(
          id: 'TC_${normalizedModule}_${(i + 1).toString().padLeft(3, '0')}',
          title: _normalizeTitle(working.title),
          preconditions: working.preconditions,
          testData: working.testData,
          steps: canonicalSteps,
          expectedResult: working.expectedResult,
          actualResult: '',
          priority: working.priority,
          status: 'Not Executed',
          type: working.type,
          module: working.module,
          feature: working.feature,
          platform: working.platform,
          source: working.metadata.source,
          dbId: null,
        ),
      );
    }
    return finalized;
  }

  String _normalizeModule(String module) {
    return module
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .toUpperCase();
  }

  String _normalizeTitle(String title) {
    return title.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}