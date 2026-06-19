import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/domains/commerce_domain.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  group('CommerceDomain', () {
    test('context has correct id', () {
      expect(CommerceDomain.context.id, equals('commerce'));
    });

    test('context has correct displayName', () {
      expect(CommerceDomain.context.displayName, equals('Commerce'));
    });

    test('context contains commerce entities', () {
      expect(CommerceDomain.context.entities, contains(EntityType.cart));
      expect(CommerceDomain.context.entities, contains(EntityType.item));
      expect(CommerceDomain.context.entities, contains(EntityType.order));
    });

    test('context contains commerce actions', () {
      expect(CommerceDomain.context.actions, contains(ActionType.checkout));
      expect(CommerceDomain.context.actions, contains(ActionType.pay));
      expect(CommerceDomain.context.actions, contains(ActionType.ship));
    });

    test('context contains commerce states', () {
      expect(CommerceDomain.context.states, contains(StateType.paid));
      expect(CommerceDomain.context.states, contains(StateType.shipped));
      expect(CommerceDomain.context.states, contains(StateType.discounted));
    });

    test('getRelationships returns non-empty list', () {
      expect(CommerceDomain.getRelationships(), isNotEmpty);
    });

    test('getRelationships contains cart-item add relationship', () {
      final rels = CommerceDomain.getRelationships();
      final found = rels.any((r) =>
          r.source == EntityType.cart &&
          r.target == EntityType.item &&
          r.action == ActionType.add);
      expect(found, isTrue);
    });

    test('all relationships have action, fromState, toState', () {
      for (final r in CommerceDomain.getRelationships()) {
        expect(r.action, isNotNull);
        expect(r.fromState, isNotNull);
        expect(r.toState, isNotNull);
      }
    });
  });
}
