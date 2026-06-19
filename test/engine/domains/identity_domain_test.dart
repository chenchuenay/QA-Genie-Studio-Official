import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/domains/identity_domain.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  group('IdentityDomain', () {
    test('context has correct id', () {
      expect(IdentityDomain.context.id, equals('identity'));
    });

    test('context has correct displayName', () {
      expect(IdentityDomain.context.displayName, equals('Identity'));
    });

    test('context contains expected entities', () {
      expect(IdentityDomain.context.entities, contains(EntityType.account));
      expect(IdentityDomain.context.entities, contains(EntityType.credential));
      expect(IdentityDomain.context.entities, contains(EntityType.session));
    });

    test('context contains expected actions', () {
      expect(IdentityDomain.context.actions, contains(ActionType.login));
      expect(IdentityDomain.context.actions, contains(ActionType.logout));
      expect(IdentityDomain.context.actions, contains(ActionType.authenticate));
    });

    test('context contains expected states', () {
      expect(IdentityDomain.context.states, contains(StateType.authenticated));
      expect(IdentityDomain.context.states, contains(StateType.authorized));
      expect(IdentityDomain.context.states, contains(StateType.locked));
    });

    test('getRelationships returns non-empty list', () {
      final relationships = IdentityDomain.getRelationships();
      expect(relationships, isNotEmpty);
    });

    test('getRelationships contains account-credential authenticate relationship', () {
      final relationships = IdentityDomain.getRelationships();
      final found = relationships.any((r) =>
          r.source == EntityType.account &&
          r.target == EntityType.credential &&
          r.action == ActionType.authenticate);
      expect(found, isTrue);
    });

    test('getRelationships contains logout relationship', () {
      final relationships = IdentityDomain.getRelationships();
      final found = relationships.any((r) => r.action == ActionType.logout);
      expect(found, isTrue);
    });

    test('all relationships have action, fromState, and toState', () {
      final relationships = IdentityDomain.getRelationships();
      for (final r in relationships) {
        expect(r.action, isNotNull);
        expect(r.fromState, isNotNull);
        expect(r.toState, isNotNull);
      }
    });
  });
}
