import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/domains/integration_domain.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  group('IntegrationDomain', () {
    test('context has correct id', () {
      expect(IntegrationDomain.context.id, equals('integration'));
    });

    test('context has correct displayName', () {
      expect(IntegrationDomain.context.displayName, equals('Integration'));
    });

    test('context contains integration entities', () {
      expect(IntegrationDomain.context.entities, contains(EntityType.webhook));
      expect(IntegrationDomain.context.entities, contains(EntityType.apiKey));
      expect(IntegrationDomain.context.entities, contains(EntityType.endpoint));
    });

    test('context contains integration actions', () {
      expect(IntegrationDomain.context.actions, contains(ActionType.send));
      expect(IntegrationDomain.context.actions, contains(ActionType.webhookTrigger));
      expect(IntegrationDomain.context.actions, contains(ActionType.retryOp));
    });

    test('context contains integration states', () {
      expect(IntegrationDomain.context.states, contains(StateType.triggered));
      expect(IntegrationDomain.context.states, contains(StateType.deliveredState));
      expect(IntegrationDomain.context.states, contains(StateType.exhausted));
    });

    test('getRelationships returns non-empty list', () {
      expect(IntegrationDomain.getRelationships(), isNotEmpty);
    });

    test('getRelationships contains webhook-event trigger', () {
      final rels = IntegrationDomain.getRelationships();
      final found = rels.any((r) =>
          r.source == EntityType.webhook &&
          r.target == EntityType.event &&
          r.action == ActionType.trigger);
      expect(found, isTrue);
    });

    test('all relationships have action, fromState, toState', () {
      for (final r in IntegrationDomain.getRelationships()) {
        expect(r.action, isNotNull);
        expect(r.fromState, isNotNull);
        expect(r.toState, isNotNull);
      }
    });
  });
}
