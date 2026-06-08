import '../ontology/states.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';

class DomainContext {
  final String id;
  final String displayName;
  final Set<EntityType> entities;
  final Set<ActionType> actions;
  final Set<StateType> states;

  const DomainContext({
    required this.id,
    required this.displayName,
    required this.entities,
    required this.actions,
    required this.states,
  });
}
