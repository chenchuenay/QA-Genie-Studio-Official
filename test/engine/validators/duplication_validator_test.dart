import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/validators/duplication_validator.dart';
import 'package:qa_genie/engine/models/scenario.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  group('DuplicationValidator', () {
    test('returns true for duplicate scenario', () {
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
      expect(DuplicationValidator.isDuplicate(s1, {s2}), isTrue);
    });

    test('returns false for different scenario', () {
      final s1 = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      final s2 = Scenario(
        entity: EntityType.account,
        action: ActionType.logout,
        targetState: StateType.unauthenticated,
        category: 'positive',
      );
      expect(DuplicationValidator.isDuplicate(s1, {s2}), isFalse);
    });

    test('returns false for empty set', () {
      final s1 = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      expect(DuplicationValidator.isDuplicate(s1, <Scenario>{}), isFalse);
    });

    test('duplicate detection uses entity+action+state only', () {
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
      expect(s1 == s2, isTrue);
      expect(DuplicationValidator.isDuplicate(s1, {s2}), isTrue);
    });
  });
}
