import 'package:qa_genie/engine/pipeline/models/pipeline_models.dart';
import 'package:qa_genie/engine/pipeline/rules/repair/repair_rule.dart';

class MissingExpectedResultRule implements RepairRule {
  @override
  String get name => 'MissingExpectedResultRule';

  @override
  bool apply(WorkingCase tc) {
    if (tc.expectedResult.trim().isEmpty) {
      tc.expectedResult = 'The ${tc.feature} system should respond with a valid state transition and verify all input constraints.';
      tc.metadata.repairHistory.add('Fixed empty expected result with dynamic fallback.');
      return true;
    }
    return false;
  }
}

class PlatformViolationRule implements RepairRule {
  @override
  String get name => 'PlatformViolationRule';

  @override
  bool apply(WorkingCase tc) {
    bool repaired = false;
    final platform = tc.platform.toLowerCase();
    
    if (platform == 'ios' && tc.title.toLowerCase().contains('android')) {
      tc.title = tc.title.replaceAll(RegExp(r'android', caseSensitive: false), 'iOS');
      repaired = true;
    } else if (platform == 'android' && tc.title.toLowerCase().contains('ios')) {
      tc.title = tc.title.replaceAll(RegExp(r'ios', caseSensitive: false), 'Android');
      repaired = true;
    }

    if (repaired) {
      tc.metadata.repairHistory.add('Repaired platform terminology mismatch in title.');
    }
    return repaired;
  }
}

class GenericPhraseRule implements RepairRule {
  @override
  String get name => 'GenericPhraseRule';

  @override
  bool apply(WorkingCase tc) {
    bool repaired = false;
    if (tc.expectedResult.toLowerCase().contains('works correctly')) {
      tc.expectedResult = tc.expectedResult.replaceAll(RegExp(r'works correctly', caseSensitive: false), 'behaves according to the ${tc.feature} specification with full data integrity');
      repaired = true;
    }
    if (repaired) {
      tc.metadata.repairHistory.add('Replaced generic "works correctly" phrase with descriptive outcome.');
    }
    return repaired;
  }
}
