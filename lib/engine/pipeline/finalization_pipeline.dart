import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/pipeline/generation_context.dart';

class FinalizationPipeline {
  static const String SCHEMA_VERSION = 'v1.4.0';

  List<FinalizedTestCase> finalize(
    GenerationContext context,
    List<WorkingCase> cases,
  ) {
    return cases.map((wc) {
      return FinalizedTestCase(
        id: wc.id,
        title: wc.title,
        module: wc.module,
        feature: wc.feature,
        platform: wc.platform,
        priority: wc.priority,
        type: wc.type,
        preconditions: List.unmodifiable(wc.preconditions),
        steps: List.unmodifiable(
          wc.steps.map(
            (s) => FinalizedTestStep(
              action: s.action.trim(),
              data: s.data.trim(),
              expected: s.expected.trim(),
            ),
          ),
        ),
        expectedResult: wc.expectedResult.trim(),
        actualResult: wc.actualResult,
        status: wc.status,
        schemaVersion: SCHEMA_VERSION,
        metadata: wc.metadata
            .copy(), // Metadata is already mostly immutable-ish or copied
      );
    }).toList();
  }
}
