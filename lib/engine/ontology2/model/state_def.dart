class StateDef {
  final String id;
  final String displayName;
  final bool isTerminal;

  const StateDef({
    required this.id,
    required this.displayName,
    this.isTerminal = false,
  });
}

class StateTransition {
  final String fromState;
  final String toState;
  final String condition;

  const StateTransition({
    required this.fromState,
    required this.toState,
    this.condition = 'valid',
  });
}

class StateGraph {
  final Map<String, StateDef> states;
  final List<StateTransition> transitions;

  const StateGraph({
    required this.states,
    this.transitions = const [],
  });
}
