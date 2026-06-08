import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';

class AiRepairEngine {
  List<WorkingCase> repair(List<WorkingCase> cases, int targetCount) {
    final repaired = <WorkingCase>[];
    for (final tc in cases) {
      var modified = false;
      final working = tc.copy();

      // Repair empty testData by extracting from steps (no template)
      if (working.testData.trim().isEmpty && working.steps.isNotEmpty) {
        working.testData = _extractTestDataFromSteps(working.steps);
        modified = true;
      }

      // Improve generic title using existing intent or feature (no template)
      if (_isGenericTitle(working.title)) {
        working.title = _improveTitle(working);
        modified = true;
      }

      // Do NOT touch expectedResult – leave as is or empty
      // Never inject fake sentences.

      if (modified) {
        working.metadata.repairHistory.add('ai_repair_engine');
        working.metadata.confidenceScore = 0.85;
      }

      repaired.add(working);
    }
    return repaired;
  }

  bool _isGenericTitle(String title) {
    final lower = title.toLowerCase();
    return lower.contains('generic') ||
        lower.contains('test for') ||
        lower.contains('sample') ||
        title.length < 10;
  }

  String _improveTitle(WorkingCase tc) {
    // Use intent_id if available, otherwise feature name
    final intent = tc.intentId != '__unknown__' && tc.intentId.isNotEmpty
        ? tc.intentId
        : tc.feature;
    return '${tc.feature} - $intent';
  }

  String _extractTestDataFromSteps(List<TestStep> steps) {
    final buffer = StringBuffer();
    for (final step in steps) {
      final data = step.data.trim();
      if (data.isNotEmpty &&
          (data.contains('@') ||
              data.toLowerCase().contains('pass') ||
              data.contains('user'))) {
        if (buffer.isNotEmpty) buffer.write('&');
        buffer.write(data);
      }
    }
    return buffer.toString();
  }
}
