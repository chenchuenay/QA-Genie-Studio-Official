import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/domains/cross_domain.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/actions.dart';

void main() {
  group('CrossDomainRelationships', () {
    test('getAll returns non-empty list', () {
      expect(CrossDomainRelationships.getAll(), isNotEmpty);
    });

    test('contains identity-commerce cross-domain link', () {
      final rels = CrossDomainRelationships.getAll();
      final found = rels.any((r) =>
          r.source == EntityType.account &&
          r.target == EntityType.cart &&
          r.action == ActionType.authenticate);
      expect(found, isTrue);
    });

    test('contains identity-transaction cross-domain link', () {
      final rels = CrossDomainRelationships.getAll();
      final found = rels.any((r) =>
          r.source == EntityType.account &&
          r.target == EntityType.accountTx &&
          r.action == ActionType.authenticate);
      expect(found, isTrue);
    });

    test('contains scheduling-integration cross-domain link', () {
      final rels = CrossDomainRelationships.getAll();
      final found = rels.any((r) =>
          r.source == EntityType.consultation &&
          r.target == EntityType.endpoint &&
          r.action == ActionType.join);
      expect(found, isTrue);
    });

    test('all relationships have action, fromState, toState', () {
      for (final r in CrossDomainRelationships.getAll()) {
        expect(r.action, isNotNull);
        expect(r.fromState, isNotNull);
        expect(r.toState, isNotNull);
      }
    });
  });
}
