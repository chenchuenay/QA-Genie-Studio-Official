import 'states.dart';
import 'actions.dart';
import 'entities.dart';

class Relationship {
  final EntityType source;
  final EntityType target;
  final ActionType? action;
  final StateType? fromState;
  final StateType? toState;

  const Relationship({
    required this.source,
    required this.target,
    this.action,
    this.fromState,
    this.toState,
  });

  bool get isStateTransition => fromState != null && toState != null;
  bool get isActionBased => action != null;
}
