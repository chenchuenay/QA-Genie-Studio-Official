import 'scenario.dart';

/// A scenario assigned to be generated, with metadata.
class ScenarioAssignment {
  final Scenario scenario;
  final int index; // position in suite
  final String? overrideTitle; // optional, for constraints

  const ScenarioAssignment({
    required this.scenario,
    required this.index,
    this.overrideTitle,
  });

  String get category => scenario.category;
  String get risk => scenario.isPositive ? 'LOW' : 'MEDIUM';
  String get outcome => '${scenario.action.name}_${scenario.targetState.name}';
}
