import 'package:qa_genie/engine/models/pipeline_models.dart';

class RealismValidator {
  const RealismValidator();

  bool validate(WorkingCase tc) {
    // Return false if any realism check fails, otherwise true
    if (!_validateTitle(tc)) return false;
    if (!_validateExpectedResult(tc)) return false;
    if (!_validateSteps(tc)) return false;
    if (!_validateData(tc)) return false;
    return true;
  }

  bool _validateTitle(WorkingCase tc) {
    final lower = tc.title.toLowerCase();
    const roboticPatterns = [
      'verify system',
      'test functionality',
      'ensure process',
      'validate workflow',
      'check operation',
    ];
    return !roboticPatterns.any(lower.contains);
  }

  bool _validateExpectedResult(WorkingCase tc) {
    final lower = tc.expectedResult.toLowerCase();
    const bannedPhrases = [
      'system works correctly',
      'operation successful',
      'workflow completed successfully',
      'processes input correctly',
    ];
    return !bannedPhrases.any(lower.contains);
  }

  bool _validateSteps(WorkingCase tc) {
    if (tc.steps.length <= 1) return false;
    final repeated = tc.steps.map((e) => e.action.trim().toLowerCase()).toSet();
    if (repeated.length < tc.steps.length / 2) return false;
    return true;
  }

  bool _validateData(WorkingCase tc) {
    for (final step in tc.steps) {
      final data = step.data.toLowerCase();
      if (data.contains('dummy data') ||
          data.contains('sample data') ||
          data.contains('test data')) {
        return false;
      }
    }
    return true;
  }
}
