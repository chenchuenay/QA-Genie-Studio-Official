import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/generators/precondition_generator.dart';
import 'package:qa_genie/engine/models/scenario.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  group('PreconditionGenerator', () {
    test('generate returns entity exists precondition for any scenario', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      final preconditions = PreconditionGenerator.generate(scenario);
      expect(preconditions, contains('account exists'));
    });

    test('generate returns ready precondition for positive scenario', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      final preconditions = PreconditionGenerator.generate(scenario);
      expect(preconditions, contains('account is ready for login'));
    });

    test('generate returns blocking precondition for negative scenario', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.failed,
        category: 'negative',
      );
      final preconditions = PreconditionGenerator.generate(scenario);
      expect(preconditions, contains('account is in a state that prevents login'));
    });

    test('generate returns two preconditions', () {
      final scenario = Scenario(
        entity: EntityType.product,
        action: ActionType.create,
        targetState: StateType.active,
        category: 'positive',
      );
      final preconditions = PreconditionGenerator.generate(scenario);
      expect(preconditions.length, 2);
    });

    test('generate uses entity display name directly', () {
      final scenario = Scenario(
        entity: EntityType.giftCard,
        action: ActionType.redeem,
        targetState: StateType.processed,
        category: 'positive',
      );
      final preconditions = PreconditionGenerator.generate(scenario);
      expect(preconditions[0], contains('gift card'));
    });
  });
}
