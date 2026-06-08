import '../models/scenario.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';

class PreconditionGenerator {
  static List<String> generate(Scenario scenario) {
    final preconditions = <String>[];
    final entity = scenario.entity.displayName;
    preconditions.add('$entity exists');
    if (scenario.isPositive) {
      preconditions.add('$entity is ready for ${scenario.action.displayName}');
    } else {
      preconditions.add(
        '$entity is in a state that prevents ${scenario.action.displayName}',
      );
    }
    return preconditions;
  }
}
