import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/generators/expected_result_generator.dart';
import 'package:qa_genie/engine/models/scenario.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  group('ExpectedResultGenerator', () {
    test('generate returns positive result for authenticated state', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Dashboard is displayed');
    });

    test('generate returns negative result for authenticated state', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'negative',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Error message: Authentication failed');
    });

    test('generate returns positive result for authorized state', () {
      final scenario = Scenario(
        entity: EntityType.permissionSet,
        action: ActionType.authorize,
        targetState: StateType.authorized,
        category: 'positive',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Protected content is visible');
    });

    test('generate returns negative result for authorized state', () {
      final scenario = Scenario(
        entity: EntityType.permissionSet,
        action: ActionType.authorize,
        targetState: StateType.authorized,
        category: 'negative',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Access denied message appears');
    });

    test('generate returns positive result for active state', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.view,
        targetState: StateType.active,
        category: 'positive',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Operation completed');
    });

    test('generate returns negative result for active state', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.view,
        targetState: StateType.active,
        category: 'negative',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Operation failed, error shown');
    });

    test('generate returns positive result for completed state', () {
      final scenario = Scenario(
        entity: EntityType.transfer,
        action: ActionType.execute,
        targetState: StateType.completed,
        category: 'positive',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Confirmation message appears');
    });

    test('generate returns negative result for completed state', () {
      final scenario = Scenario(
        entity: EntityType.transfer,
        action: ActionType.execute,
        targetState: StateType.completed,
        category: 'negative',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Transaction failed');
    });

    test('generate returns positive result for created state', () {
      final scenario = Scenario(
        entity: EntityType.appointment,
        action: ActionType.create,
        targetState: StateType.created,
        category: 'positive',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'New item is created');
    });

    test('generate returns negative result for created state', () {
      final scenario = Scenario(
        entity: EntityType.appointment,
        action: ActionType.create,
        targetState: StateType.created,
        category: 'negative',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Creation failed');
    });

    test('generate returns positive result for updated state', () {
      final scenario = Scenario(
        entity: EntityType.record,
        action: ActionType.update,
        targetState: StateType.updated,
        category: 'positive',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Changes are saved');
    });

    test('generate returns negative result for updated state', () {
      final scenario = Scenario(
        entity: EntityType.record,
        action: ActionType.update,
        targetState: StateType.updated,
        category: 'negative',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Update failed');
    });

    test('generate returns positive result for deleted state', () {
      final scenario = Scenario(
        entity: EntityType.session,
        action: ActionType.delete,
        targetState: StateType.deleted,
        category: 'positive',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Item is removed');
    });

    test('generate returns negative result for deleted state', () {
      final scenario = Scenario(
        entity: EntityType.session,
        action: ActionType.delete,
        targetState: StateType.deleted,
        category: 'negative',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Deletion failed');
    });

    test('generate returns positive result for scheduled state', () {
      final scenario = Scenario(
        entity: EntityType.appointment,
        action: ActionType.book,
        targetState: StateType.scheduled,
        category: 'positive',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Appointment confirmed');
    });

    test('generate returns negative result for scheduled state', () {
      final scenario = Scenario(
        entity: EntityType.appointment,
        action: ActionType.book,
        targetState: StateType.scheduled,
        category: 'negative',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Scheduling failed');
    });

    test('generate returns positive result for redirected state', () {
      final scenario = Scenario(
        entity: EntityType.session,
        action: ActionType.login,
        targetState: StateType.redirected,
        category: 'positive',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Page redirects');
    });

    test('generate returns negative result for redirected state', () {
      final scenario = Scenario(
        entity: EntityType.session,
        action: ActionType.login,
        targetState: StateType.redirected,
        category: 'negative',
      );
      expect(ExpectedResultGenerator.generate(scenario), 'Redirect failed');
    });

    test('generate returns default outcome for unknown state', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.abnormal,
        category: 'positive',
      );
      expect(ExpectedResultGenerator.generate(scenario), equals('Success'));
    });

    test('generate returns default negative outcome for unknown state', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.abnormal,
        category: 'negative',
      );
      expect(ExpectedResultGenerator.generate(scenario), equals('Error'));
    });
  });
}
