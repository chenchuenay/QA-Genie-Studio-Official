import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/domains/scheduling_domain.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  group('SchedulingDomain', () {
    test('context has correct id', () {
      expect(SchedulingDomain.context.id, equals('scheduling'));
    });

    test('context has correct displayName', () {
      expect(SchedulingDomain.context.displayName, equals('Scheduling'));
    });

    test('context contains scheduling entities', () {
      expect(SchedulingDomain.context.entities, contains(EntityType.appointment));
      expect(SchedulingDomain.context.entities, contains(EntityType.provider));
      expect(SchedulingDomain.context.entities, contains(EntityType.slot));
    });

    test('context contains scheduling actions', () {
      expect(SchedulingDomain.context.actions, contains(ActionType.book));
      expect(SchedulingDomain.context.actions, contains(ActionType.reschedule));
      expect(SchedulingDomain.context.actions, contains(ActionType.confirm));
    });

    test('context contains scheduling states', () {
      expect(SchedulingDomain.context.states, contains(StateType.booked));
      expect(SchedulingDomain.context.states, contains(StateType.available));
      expect(SchedulingDomain.context.states, contains(StateType.cancelled));
    });

    test('getRelationships returns non-empty list', () {
      expect(SchedulingDomain.getRelationships(), isNotEmpty);
    });

    test('getRelationships contains patient-create-appointment', () {
      final rels = SchedulingDomain.getRelationships();
      final found = rels.any((r) =>
          r.source == EntityType.patient &&
          r.target == EntityType.appointment &&
          r.action == ActionType.create);
      expect(found, isTrue);
    });

    test('all relationships have action, fromState, toState', () {
      for (final r in SchedulingDomain.getRelationships()) {
        expect(r.action, isNotNull);
        expect(r.fromState, isNotNull);
        expect(r.toState, isNotNull);
      }
    });
  });
}
