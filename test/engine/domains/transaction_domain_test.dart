import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/domains/transaction_domain.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  group('TransactionDomain', () {
    test('context has correct id', () {
      expect(TransactionDomain.context.id, equals('transaction'));
    });

    test('context has correct displayName', () {
      expect(TransactionDomain.context.displayName, equals('Transaction'));
    });

    test('context contains transaction entities', () {
      expect(TransactionDomain.context.entities, contains(EntityType.wallet));
      expect(TransactionDomain.context.entities, contains(EntityType.transfer));
      expect(TransactionDomain.context.entities, contains(EntityType.beneficiary));
    });

    test('context contains transaction actions', () {
      expect(TransactionDomain.context.actions, contains(ActionType.transfer));
      expect(TransactionDomain.context.actions, contains(ActionType.deposit));
      expect(TransactionDomain.context.actions, contains(ActionType.withdraw));
    });

    test('context contains transaction states', () {
      expect(TransactionDomain.context.states, contains(StateType.sufficient));
      expect(TransactionDomain.context.states, contains(StateType.insufficient));
      expect(TransactionDomain.context.states, contains(StateType.completed));
    });

    test('getRelationships returns non-empty list', () {
      expect(TransactionDomain.getRelationships(), isNotEmpty);
    });

    test('getRelationships contains accountTx-beneficiary transfer', () {
      final rels = TransactionDomain.getRelationships();
      final found = rels.any((r) =>
          r.source == EntityType.accountTx &&
          r.target == EntityType.beneficiary &&
          r.action == ActionType.transfer);
      expect(found, isTrue);
    });

    test('all relationships have action, fromState, toState', () {
      for (final r in TransactionDomain.getRelationships()) {
        expect(r.action, isNotNull);
        expect(r.fromState, isNotNull);
        expect(r.toState, isNotNull);
      }
    });
  });
}
