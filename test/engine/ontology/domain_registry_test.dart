import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/ontology/domain_registry.dart';

void main() {
  group('EntityState', () {
    test('has all expected enum values', () {
      expect(EntityState.values, contains(EntityState.idle));
      expect(EntityState.values, contains(EntityState.inMotion));
      expect(EntityState.values, contains(EntityState.initialized));
      expect(EntityState.values, contains(EntityState.processed));
      expect(EntityState.values, contains(EntityState.error));
      expect(EntityState.values, contains(EntityState.authenticated));
      expect(EntityState.values, contains(EntityState.approved));
    });
  });

  group('ActionPattern', () {
    test('can be created with all parameters', () {
      final pattern = ActionPattern(
        requiredPreconditions: [EntityState.idle],
        postCondition: EntityState.authenticated,
        stepsByPlatform: {
          'Mobile': ['Step1', 'Step2'],
        },
        requiredConstraints: ['constraint1'],
      );
      expect(pattern.requiredPreconditions, [EntityState.idle]);
      expect(pattern.postCondition, EntityState.authenticated);
      expect(pattern.stepsByPlatform, {'Mobile': ['Step1', 'Step2']});
      expect(pattern.requiredConstraints, ['constraint1']);
    });

    test('requiredConstraints defaults to empty list', () {
      final pattern = ActionPattern(
        requiredPreconditions: [EntityState.idle],
        postCondition: EntityState.processed,
        stepsByPlatform: {},
      );
      expect(pattern.requiredConstraints, isEmpty);
    });
  });

  group('DomainRegistry', () {
    test('contains all expected domains', () {
      expect(DomainRegistry.ontology.containsKey('Identity'), isTrue);
      expect(DomainRegistry.ontology.containsKey('Commerce'), isTrue);
      expect(DomainRegistry.ontology.containsKey('Transaction'), isTrue);
      expect(DomainRegistry.ontology.containsKey('Scheduling'), isTrue);
      expect(DomainRegistry.ontology.containsKey('Records'), isTrue);
      expect(DomainRegistry.ontology.containsKey('Integration'), isTrue);
    });

    test('Identity domain has login and reset actions', () {
      final identity = DomainRegistry.ontology['Identity']!;
      expect(identity.containsKey('login'), isTrue);
      expect(identity.containsKey('reset'), isTrue);
    });

    test('Identity login has correct preconditions and postcondition', () {
      final login = DomainRegistry.ontology['Identity']!['login']!;
      expect(login.requiredPreconditions, [EntityState.idle]);
      expect(login.postCondition, EntityState.authenticated);
    });

    test('Identity login has Mobile, Web, and API platforms', () {
      final login = DomainRegistry.ontology['Identity']!['login']!;
      expect(login.stepsByPlatform.containsKey('Mobile'), isTrue);
      expect(login.stepsByPlatform.containsKey('Web'), isTrue);
      expect(login.stepsByPlatform.containsKey('API'), isTrue);
    });

    test('Identity reset has Mobile and Web platforms', () {
      final reset = DomainRegistry.ontology['Identity']!['reset']!;
      expect(reset.stepsByPlatform.containsKey('Mobile'), isTrue);
      expect(reset.stepsByPlatform.containsKey('Web'), isTrue);
      expect(reset.stepsByPlatform.containsKey('API'), isFalse);
    });

    test('Commerce domain has add and checkout actions', () {
      final commerce = DomainRegistry.ontology['Commerce']!;
      expect(commerce.containsKey('add'), isTrue);
      expect(commerce.containsKey('checkout'), isTrue);
    });

    test('Commerce add has correct preconditions', () {
      final add = DomainRegistry.ontology['Commerce']!['add']!;
      expect(add.requiredPreconditions, [EntityState.initialized]);
      expect(add.postCondition, EntityState.processed);
    });

    test('Transaction domain has transfer action', () {
      final transaction = DomainRegistry.ontology['Transaction']!;
      expect(transaction.containsKey('transfer'), isTrue);
    });

    test('Transaction transfer has correct preconditions', () {
      final transfer = DomainRegistry.ontology['Transaction']!['transfer']!;
      expect(transfer.requiredPreconditions, [EntityState.authenticated]);
      expect(transfer.postCondition, EntityState.processed);
    });

    test('Scheduling domain has create action', () {
      final scheduling = DomainRegistry.ontology['Scheduling']!;
      expect(scheduling.containsKey('create'), isTrue);
    });

    test('Records domain has view action', () {
      final records = DomainRegistry.ontology['Records']!;
      expect(records.containsKey('view'), isTrue);
    });

    test('Integration domain has send action', () {
      final integration = DomainRegistry.ontology['Integration']!;
      expect(integration.containsKey('send'), isTrue);
    });

    test('Integration send only has API platform', () {
      final send = DomainRegistry.ontology['Integration']!['send']!;
      expect(send.stepsByPlatform.containsKey('API'), isTrue);
      expect(send.stepsByPlatform.containsKey('Mobile'), isFalse);
      expect(send.stepsByPlatform.containsKey('Web'), isFalse);
    });

    test('All steps are non-empty strings', () {
      for (final domain in DomainRegistry.ontology.values) {
        for (final pattern in domain.values) {
          for (final steps in pattern.stepsByPlatform.values) {
            for (final step in steps) {
              expect(step, isNotEmpty);
            }
          }
        }
      }
    });
  });
}
