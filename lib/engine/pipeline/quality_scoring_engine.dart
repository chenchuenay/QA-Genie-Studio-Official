import 'package:qa_genie/engine/models/pipeline_models.dart';

class QualityScoringEngine {
  double calculateConfidence(WorkingCase tc) {
    double confidence = 1.0;

    // Penalty for weak expected result
    if (tc.expectedResult.length < 30 ||
        tc.expectedResult.toLowerCase().contains('works correctly')) {
      confidence -= 0.3;
      tc.metadata.qualityPenalties['weak_expected_result'] = 0.3;
    }

    // Penalty for generic title
    if (tc.title.length < 15) {
      confidence -= 0.1;
      tc.metadata.qualityPenalties['short_title'] = 0.1;
    }

    // Penalty for high repair intensity
    if (tc.metadata.repairHistory.length > 2) {
      confidence -= 0.2;
      tc.metadata.qualityPenalties['high_repair_intensity'] = 0.2;
    }

    // Penalty for insufficient step detail
    if (tc.steps.any((s) => s.data.isEmpty)) {
      confidence -= 0.1;
      tc.metadata.qualityPenalties['missing_step_data'] = 0.1;
    }

    tc.metadata.confidenceScore = confidence.clamp(0.0, 1.0);
    return tc.metadata.confidenceScore;
  }
}
