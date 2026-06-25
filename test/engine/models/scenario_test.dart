import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/ontology/states.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/models/scenario.dart';

void main() {
  group('Scenario', () {
    test('can be created with entity, action, targetState, category', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      expect(scenario.entity, EntityType.account);
      expect(scenario.action, ActionType.login);
      expect(scenario.targetState, StateType.authenticated);
      expect(scenario.category, 'positive');
      expect(scenario.isPositive, isTrue);
    });

    test('isPositive is false for non-positive category', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'negative',
      );
      expect(scenario.isPositive, isFalse);
    });

    test('equality works based on entity, action, targetState', () {
      final s1 = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      final s2 = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'negative',
      );
      final s3 = Scenario(
        entity: EntityType.account,
        action: ActionType.logout,
        targetState: StateType.unauthenticated,
        category: 'positive',
      );
      expect(s1 == s2, isTrue);
      expect(s1 == s3, isFalse);
    });

    test('hashCode is consistent with equality', () {
      final s1 = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      final s2 = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'negative',
      );
      expect(s1.hashCode == s2.hashCode, isTrue);
    });

    test('identical instances are equal', () {
      final s1 = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      expect(s1 == s1, isTrue);
    });

    test('toString returns formatted string', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      final str = scenario.toString();
      expect(str, contains('Scenario'));
      expect(str, contains('account'));
      expect(str, contains('login'));
      expect(str, contains('authenticated'));
      expect(str, contains('positive'));
    });
  });
}
