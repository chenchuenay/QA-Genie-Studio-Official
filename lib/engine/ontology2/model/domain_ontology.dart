import 'entity_def.dart';
import 'action_def.dart';
import 'state_def.dart';

class OntologyRelationship {
  final String sourceEntity;
  final String targetEntity;
  final String action;

  const OntologyRelationship({
    required this.sourceEntity,
    required this.targetEntity,
    required this.action,
  });
}

class DomainOntology {
  final String id;
  final String displayName;
  final List<String> synonyms;
  final Map<String, EntityDef> entities;
  final Map<String, ActionDef> actions;
  final StateGraph stateGraph;
  final List<OntologyRelationship> relationships;
  final List<DomainOntology> subDomains;

  const DomainOntology({
    required this.id,
    required this.displayName,
    this.synonyms = const [],
    this.entities = const {},
    this.actions = const {},
    this.stateGraph = const StateGraph(states: {}),
    this.relationships = const [],
    this.subDomains = const [],
  });

  EntityDef? entity(String id) => entities[id];
  ActionDef? action(String id) => actions[id];
}
