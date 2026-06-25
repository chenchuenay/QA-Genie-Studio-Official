import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/states.dart';
import 'package:qa_genie/engine/ontology/relationships.dart';

void main() {
  group('Relationship', () {
    test('can create a basic relationship with source and target only', () {
      final rel = Relationship(
        source: EntityType.account,
        target: EntityType.session,
      );
      expect(rel.source, EntityType.account);
      expect(rel.target, EntityType.session);
      expect(rel.action, isNull);
      expect(rel.fromState, isNull);
      expect(rel.toState, isNull);
      expect(rel.isStateTransition, isFalse);
      expect(rel.isActionBased, isFalse);
    });

    test('can create an action-based relationship', () {
      final rel = Relationship(
        source: EntityType.account,
        target: EntityType.session,
        action: ActionType.create,
      );
      expect(rel.action, ActionType.create);
      expect(rel.isActionBased, isTrue);
      expect(rel.isStateTransition, isFalse);
    });

    test('can create a state transition relationship', () {
      final rel = Relationship(
        source: EntityType.session,
        target: EntityType.session,
        fromState: StateType.active,
        toState: StateType.expired,
      );
      expect(rel.fromState, StateType.active);
      expect(rel.toState, StateType.expired);
      expect(rel.isStateTransition, isTrue);
      expect(rel.isActionBased, isFalse);
    });

    test('can create a full relationship with action and state', () {
      final rel = Relationship(
        source: EntityType.order,
        target: EntityType.order,
        action: ActionType.update,
        fromState: StateType.pending,
        toState: StateType.confirmed,
      );
      expect(rel.source, EntityType.order);
      expect(rel.target, EntityType.order);
      expect(rel.action, ActionType.update);
      expect(rel.fromState, StateType.pending);
      expect(rel.toState, StateType.confirmed);
      expect(rel.isStateTransition, isTrue);
      expect(rel.isActionBased, isTrue);
    });

    test('isStateTransition returns false when only fromState is set', () {
      final rel = Relationship(
        source: EntityType.account,
        target: EntityType.session,
        fromState: StateType.active,
      );
      expect(rel.isStateTransition, isFalse);
    });

    test('isStateTransition returns false when only toState is set', () {
      final rel = Relationship(
        source: EntityType.account,
        target: EntityType.session,
        toState: StateType.expired,
      );
      expect(rel.isStateTransition, isFalse);
    });

    test('Relationship is const', () {
      const rel = Relationship(
        source: EntityType.account,
        target: EntityType.profile,
      );
      expect(rel.source, EntityType.account);
    });
  });
}
