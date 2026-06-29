import '../model/entity_def.dart';
import '../model/action_def.dart';
import '../model/domain_ontology.dart';

class OntologyScenario {
  final String entityId;
  final String actionId;
  final String category;
  final String condition;
  final bool isPositive;

  OntologyScenario({
    required this.entityId,
    required this.actionId,
    required this.category,
    this.condition = 'valid',
  }) : isPositive = category == 'positive';
}

class OntologyScenarioPlanner {
  final DomainOntology domain;
  final int targetCount;

  OntologyScenarioPlanner({
    required this.domain,
    required this.targetCount,
  });

  List<OntologyScenario> plan() {
    final scenarios = <OntologyScenario>[];
    final categories = ['positive', 'negative', 'validation', 'security', 'boundary'];
    final conditionsByCategory = <String, List<String>>{
      'positive': ['valid'],
      'negative': ['invalid', 'expired', 'revoked'],
      'validation': ['empty', 'invalid_format', 'max_length'],
      'security': ['sql_injection', 'xss', 'csrf_mismatch'],
      'boundary': ['maximum', 'minimum'],
    };

    final entityActionPairs = <(String, String)>[];
    for (final entity in domain.entities.values) {
      for (final action in domain.actions.values) {
        entityActionPairs.add((entity.id, action.id));
      }
    }

    if (entityActionPairs.isEmpty) {
      entityActionPairs.add((domain.entities.values.first.id, domain.actions.values.first.id));
    }

    int catIdx = 0;
    int condIdx = 0;
    int pairIdx = 0;

    while (scenarios.length < targetCount) {
      final category = categories[catIdx % categories.length];
      final conditions = conditionsByCategory[category]!;
      final condition = conditions[condIdx % conditions.length];
      final pair = entityActionPairs[pairIdx % entityActionPairs.length];

      scenarios.add(OntologyScenario(
        entityId: pair.$1,
        actionId: pair.$2,
        category: category,
        condition: condition,
      ));

      condIdx++;
      if (condIdx % conditions.length == 0) {
        catIdx++;
        if (catIdx % categories.length == 0) {
          pairIdx++;
        }
      }

      // Safety valve
      if (pairIdx > entityActionPairs.length * 3) break;
    }

    return scenarios.take(targetCount).toList();
  }
}
