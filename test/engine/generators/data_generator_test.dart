import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/generators/data_generator.dart';
import 'package:qa_genie/engine/models/scenario.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  group('DataGenerator', () {
    test('generate returns email and password for login action', () {
      final scenario = Scenario(
        entity: EntityType.credential,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      final data = DataGenerator.generate(scenario, '');
      expect(data.containsKey('email'), isTrue);
      expect(data.containsKey('password'), isTrue);
    });

    test('generate returns email and password for authenticate action', () {
      final scenario = Scenario(
        entity: EntityType.credential,
        action: ActionType.authenticate,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      final data = DataGenerator.generate(scenario, '');
      expect(data.containsKey('email'), isTrue);
      expect(data.containsKey('password'), isTrue);
    });

    test('generate returns refresh_token for refresh action', () {
      final scenario = Scenario(
        entity: EntityType.session,
        action: ActionType.refresh,
        targetState: StateType.active,
        category: 'positive',
      );
      final data = DataGenerator.generate(scenario, '');
      expect(data.containsKey('refresh_token'), isTrue);
    });

    test('generate returns payment data for pay action', () {
      final scenario = Scenario(
        entity: EntityType.payment,
        action: ActionType.pay,
        targetState: StateType.paid,
        category: 'positive',
      );
      final data = DataGenerator.generate(scenario, '');
      expect(data.containsKey('card_number'), isTrue);
      expect(data.containsKey('expiry'), isTrue);
      expect(data.containsKey('cvv'), isTrue);
    });

    test('generate returns coupon_code for apply action with coupon entity', () {
      final scenario = Scenario(
        entity: EntityType.coupon,
        action: ActionType.apply,
        targetState: StateType.discounted,
        category: 'positive',
      );
      final data = DataGenerator.generate(scenario, '');
      expect(data.containsKey('coupon_code'), isTrue);
    });

    test('generate returns amount and beneficiary for transfer action', () {
      final scenario = Scenario(
        entity: EntityType.transfer,
        action: ActionType.transfer,
        targetState: StateType.completed,
        category: 'positive',
      );
      final data = DataGenerator.generate(scenario, '');
      expect(data.containsKey('amount'), isTrue);
      expect(data.containsKey('beneficiary'), isTrue);
    });

    test('generate returns slot for create action with appointment entity', () {
      final scenario = Scenario(
        entity: EntityType.appointment,
        action: ActionType.create,
        targetState: StateType.pending,
        category: 'positive',
      );
      final data = DataGenerator.generate(scenario, '');
      expect(data.containsKey('slot'), isTrue);
    });

    test('generate adds sql_payload when constraints mention sql', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.view,
        targetState: StateType.active,
        category: 'positive',
      );
      final data = DataGenerator.generate(scenario, 'test with sql injection');
      expect(data.containsKey('sql_payload'), isTrue);
    });

    test('generate adds xss_payload when constraints mention xss', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.view,
        targetState: StateType.active,
        category: 'positive',
      );
      final data = DataGenerator.generate(scenario, 'check xss vulnerability');
      expect(data.containsKey('xss_payload'), isTrue);
    });

    test('generate adds both sql and xss payloads when both in constraints', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.view,
        targetState: StateType.active,
        category: 'positive',
      );
      final data = DataGenerator.generate(scenario, 'sql and xss');
      expect(data.containsKey('sql_payload'), isTrue);
      expect(data.containsKey('xss_payload'), isTrue);
    });

    test('generate returns fallback entity_id for unmatched action', () {
      final scenario = Scenario(
        entity: EntityType.product,
        action: ActionType.view,
        targetState: StateType.active,
        category: 'positive',
      );
      final data = DataGenerator.generate(scenario, '');
      expect(data.containsKey('entity_id'), isTrue);
      expect(data['entity_id'], contains('PRODUCT'));
    });

    test('generate populates both specific data and security payloads', () {
      final scenario = Scenario(
        entity: EntityType.credential,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'positive',
      );
      final data = DataGenerator.generate(scenario, 'sql injection test');
      expect(data.containsKey('email'), isTrue);
      expect(data.containsKey('password'), isTrue);
      expect(data.containsKey('sql_payload'), isTrue);
    });
  });
}
