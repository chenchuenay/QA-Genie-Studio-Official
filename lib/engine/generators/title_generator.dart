import '../models/scenario.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';

class TitleGenerator {
  static String generate(Scenario scenario, String feature) {
    final action = scenario.action.displayName;
    final entity = scenario.entity.displayName;
    final capAction = action[0].toUpperCase() + action.substring(1);
    final capEntity = entity[0].toUpperCase() + entity.substring(1);

    if (scenario.category == 'positive') {
      final templates = [
        '$capAction $capEntity — verify successful $action of $entity in $feature',
        'Successful $action — $entity is processed correctly in $feature',
        '$feature — $capAction $capEntity with valid data',
      ];
      return templates[scenario.action.index % templates.length];
    } else if (scenario.category == 'negative') {
      final templates = [
        '$capAction $capEntity — verify error handling when $entity $action fails',
        '$feature — $capAction with invalid $entity returns appropriate error',
        'Failed $action — $entity rejection is handled gracefully in $feature',
      ];
      return templates[scenario.action.index % templates.length];
    } else if (scenario.category == 'validation') {
      return '$feature — validate $entity input constraints during $action';
    } else if (scenario.category == 'security') {
      return '$feature — security: $entity $action with malicious input is rejected';
    } else if (scenario.category == 'boundary') {
      return '$feature — boundary test: $entity $action at maximum allowed values';
    } else if (scenario.category == 'session') {
      return '$feature — session: $entity $action after session expiry is blocked';
    }
    return '$capAction $capEntity — $feature';
  }
}
