import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/domains/records_domain.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  group('RecordsDomain', () {
    test('context has correct id', () {
      expect(RecordsDomain.context.id, equals('records'));
    });

    test('context has correct displayName', () {
      expect(RecordsDomain.context.displayName, equals('Records'));
    });

    test('context contains records entities', () {
      expect(RecordsDomain.context.entities, contains(EntityType.record));
      expect(RecordsDomain.context.entities, contains(EntityType.labResult));
      expect(RecordsDomain.context.entities, contains(EntityType.prescription));
    });

    test('context contains records actions', () {
      expect(RecordsDomain.context.actions, contains(ActionType.view));
      expect(RecordsDomain.context.actions, contains(ActionType.share));
      expect(RecordsDomain.context.actions, contains(ActionType.requestRefill));
    });

    test('context contains records states', () {
      expect(RecordsDomain.context.states, contains(StateType.shared));
      expect(RecordsDomain.context.states, contains(StateType.restricted));
      expect(RecordsDomain.context.states, contains(StateType.flagged));
    });

    test('getRelationships returns non-empty list', () {
      expect(RecordsDomain.getRelationships(), isNotEmpty);
    });

    test('getRelationships contains patient-record view relationship', () {
      final rels = RecordsDomain.getRelationships();
      final found = rels.any((r) =>
          r.source == EntityType.patient &&
          r.target == EntityType.record &&
          r.action == ActionType.view);
      expect(found, isTrue);
    });

    test('all relationships have action, fromState, toState', () {
      for (final r in RecordsDomain.getRelationships()) {
        expect(r.action, isNotNull);
        expect(r.fromState, isNotNull);
        expect(r.toState, isNotNull);
      }
    });
  });
}
