import 'package:qa_genie/engine/models/pipeline_models.dart';

class RealismValidator {
  static List<WorkingCase> validate(List<WorkingCase> cases) {
    final seenTitles = <String, int>{};
    final seenOutcomeKeys = <String, int>{};
    final valid = <WorkingCase>[];

    for (final wc in cases) {
      final titleKey = wc.title.trim().toLowerCase();
      seenTitles[titleKey] = (seenTitles[titleKey] ?? 0) + 1;
      final outcomeKey = wc.intentId;
      seenOutcomeKeys[outcomeKey] = (seenOutcomeKeys[outcomeKey] ?? 0) + 1;

      if (seenTitles[titleKey]! > 1) {
        print('RealismValidator: duplicate title "${wc.title}"');
      }
      if (seenOutcomeKeys[outcomeKey]! > 3) {
        print('RealismValidator: too many repetitions of outcome $outcomeKey');
      }
      valid.add(wc);
    }
    return valid;
  }
}
