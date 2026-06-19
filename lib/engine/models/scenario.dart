import '../ontology/states.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';

/// A scenario is a unique combination that defines a test case.
class Scenario {
  final EntityType entity;
  final ActionType action;
  final StateType targetState; // the state we expect after action
  final String
  category; // positive, negative, validation, boundary, security, session
  final String
  condition; // specific condition driving this scenario (sql_injection, xss, invalid, empty, etc.)
  final bool isPositive; // derived from category

  Scenario({
    required this.entity,
    required this.action,
    required this.targetState,
    required this.category,
    this.condition = 'valid',
  }) : isPositive = category == 'positive';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Scenario &&
        other.entity == entity &&
        other.action == action &&
        other.targetState == targetState &&
        other.condition == condition;
  }

  @override
  int get hashCode => Object.hash(entity, action, targetState, condition);

  @override
  String toString() => 'Scenario($entity, $action, $targetState, $category, $condition)';
}
