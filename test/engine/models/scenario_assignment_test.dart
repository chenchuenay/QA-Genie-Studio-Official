import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/ontology/states.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/models/scenario.dart';
import 'package:qa_genie/engine/models/scenario_assignment.dart';

void main() {
  group('ScenarioAssignment', () {
    final scenario = Scenario(
      entity: EntityType.user,
      action: ActionType.login,
      targetState: StateType.authenticated,
      category: 'positive',
    );

    test('can be created with scenario, index, and optional overrideTitle', () {
      final assignment = ScenarioAssignment(
        scenario: scenario,
        index: 0,
      );
      expect(assignment.scenario, scenario);
      expect(assignment.index, 0);
      expect(assignment.overrideTitle, isNull);
    });

    test('can be created with overrideTitle', () {
      final assignment = ScenarioAssignment(
        scenario: scenario,
        index: 1,
        overrideTitle: 'Custom login test',
      );
      expect(assignment.overrideTitle, 'Custom login test');
    });

    test('category delegates to scenario.category', () {
      final assignment = ScenarioAssignment(
        scenario: scenario,
        index: 0,
      );
      expect(assignment.category, 'positive');
    });

    test('risk returns LOW for positive scenario', () {
      final assignment = ScenarioAssignment(
        scenario: scenario,
        index: 0,
      );
      expect(assignment.risk, 'LOW');
    });

    test('risk returns MEDIUM for non-positive scenario', () {
      final negativeScenario = Scenario(
        entity: EntityType.user,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'negative',
      );
      final assignment = ScenarioAssignment(
        scenario: negativeScenario,
        index: 0,
      );
      expect(assignment.risk, 'MEDIUM');
    });

    test('outcome returns action_targetState format', () {
      final assignment = ScenarioAssignment(
        scenario: scenario,
        index: 0,
      );
      expect(assignment.outcome, 'login_authenticated');
    });
  });
}
