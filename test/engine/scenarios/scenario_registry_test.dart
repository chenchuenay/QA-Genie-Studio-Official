import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/models/domain_context.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/states.dart';
import 'package:qa_genie/engine/scenarios/scenario_registry.dart';

void main() {
  group('ScenarioRegistry', () {
    test('getForDomain returns non-empty list for identity', () {
      final domain = DomainContext(
        id: 'identity',
        displayName: 'Identity',
        entities: {EntityType.account},
        actions: {ActionType.login},
        states: {StateType.active},
      );
      final scenarios = ScenarioRegistry.getForDomain(domain);
      expect(scenarios, isNotEmpty);
    });

    test('getForDomain returns cached results on second call', () {
      final domain = DomainContext(
        id: 'identity',
        displayName: 'Identity',
        entities: {EntityType.account},
        actions: {ActionType.login},
        states: {StateType.active},
      );
      final first = ScenarioRegistry.getForDomain(domain);
      final second = ScenarioRegistry.getForDomain(domain);
      expect(first, same(second));
    });

    test('getForDomain returns different results for different domains', () {
      final identityDomain = DomainContext(
        id: 'identity',
        displayName: 'Identity',
        entities: {EntityType.account},
        actions: {ActionType.login},
        states: {StateType.active},
      );
      final commerceDomain = DomainContext(
        id: 'commerce',
        displayName: 'Commerce',
        entities: {EntityType.cart},
        actions: {ActionType.add},
        states: {StateType.active},
      );
      final identityScenarios = ScenarioRegistry.getForDomain(identityDomain);
      final commerceScenarios = ScenarioRegistry.getForDomain(commerceDomain);
      expect(identityScenarios, isNot(same(commerceScenarios)));
    });
  });
}
