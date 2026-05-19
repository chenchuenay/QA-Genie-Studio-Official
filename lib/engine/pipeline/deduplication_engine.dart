import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/pipeline/generation_context.dart';

class DeduplicationResult {
  final List<WorkingCase> cases;
  final Map<int, String> droppedReasons;

  DeduplicationResult({required this.cases, required this.droppedReasons});
}

class DeduplicationEngine {
  DeduplicationResult deduplicate(
    GenerationContext context,
    List<WorkingCase> cases,
  ) {
    final unique = <WorkingCase>[];
    final fingerprints = <String>{};
    final dropped = <int, String>{};

    for (var index = 0; index < cases.length; index++) {
      final tc = cases[index];
      final fingerprint = tc.metadata.fingerprint ?? 'unknown-${index}';

      if (fingerprints.contains(fingerprint)) {
        dropped[index] = 'Duplicate fingerprint: $fingerprint';
        context.logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: 'Duplicate fingerprint: $fingerprint',
            stage: 'Deduplication',
          ),
        );
        continue;
      }

      fingerprints.add(fingerprint);
      unique.add(tc.copy());
    }

    return DeduplicationResult(cases: unique, droppedReasons: dropped);
  }
}
