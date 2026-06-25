import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/models/domain_context.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/states.dart';
import 'package:qa_genie/engine/scenarios/scenario_factory.dart';

void main() {
  group('ScenarioFactory', () {
    test('fromDomain returns non-empty list for identity domain', () {
      final domain = DomainContext(
        id: 'identity',
        displayName: 'Identity',
        entities: {EntityType.account},
        actions: {ActionType.login},
        states: {StateType.active},
      );
      final scenarios = ScenarioFactory.fromDomain(domain);
      expect(scenarios, isNotEmpty);
    });

    test('fromDomain returns non-empty list for commerce domain', () {
      final domain = DomainContext(
        id: 'commerce',
        displayName: 'Commerce',
        entities: {EntityType.cart},
        actions: {ActionType.add},
        states: {StateType.active},
      );
      final scenarios = ScenarioFactory.fromDomain(domain);
      expect(scenarios, isNotEmpty);
    });

    test('fromDomain returns non-empty list for an unknown domain using fallback', () {
      final domain = DomainContext(
        id: 'unknown',
        displayName: 'Unknown',
        entities: {EntityType.account},
        actions: {ActionType.login},
        states: {StateType.active},
      );
      final scenarios = ScenarioFactory.fromDomain(domain);
      expect(scenarios, isNotEmpty);
    });

    test('all scenarios have required fields', () {
      final domain = DomainContext(
        id: 'identity',
        displayName: 'Identity',
        entities: {EntityType.account},
        actions: {ActionType.login},
        states: {StateType.active},
      );
      final scenarios = ScenarioFactory.fromDomain(domain);
      for (final s in scenarios) {
        expect(s.entity, isNotNull);
        expect(s.action, isNotNull);
        expect(s.targetState, isNotNull);
        expect(s.category, isNotEmpty);
      }
    });

    test('scenarios include cross-domain relationships', () {
      final domain = DomainContext(
        id: 'identity',
        displayName: 'Identity',
        entities: {},
        actions: {},
        states: {},
      );
      final scenarios = ScenarioFactory.fromDomain(domain);
      expect(scenarios, isNotEmpty);
    });
  });
}
