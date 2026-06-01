import 'package:qa_genie/engine/business/business_area.dart';
import 'package:qa_genie/engine/scenario/scenario_rules.dart';

class TitleComposer {
  static String compose({
    required String outcome,
    required BusinessArea businessArea,
    required String feature,
    required String primaryObservation,
  }) {
    // Use outcome description as base, not the observation
    final base = _baseFromOutcome(outcome, businessArea, feature);
    // Remove trailing period and capitalize
    return base;
  }

  static String _baseFromOutcome(
    String outcome,
    BusinessArea area,
    String feature,
  ) {
    final desc = ScenarioRules.describeOutcome(outcome);
    final subject = _subjectFromBusinessArea(area);
    if (desc.contains(' ')) {
      return 'Verify ${desc} for $subject';
    } else {
      return 'Verify ${desc} $subject';
    }
  }

  static String _subjectFromBusinessArea(BusinessArea area) {
    switch (area.id) {
      case 'authentication':
        return 'user';
      case 'ecommerce':
        return 'order';
      case 'banking':
        return 'transaction';
      default:
        return 'process';
    }
  }
}
