import '../models/scenario.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';

class TitleGenerator {
  static String generate(Scenario scenario, String feature) {
    final action = scenario.action.displayName;
    final entity = scenario.entity.displayName;
    if (scenario.isPositive) {
      return '$action $entity';
    } else {
      return '$action $entity fails';
    }
  }
}
