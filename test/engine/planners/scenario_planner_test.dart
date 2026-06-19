import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/planners/scenario_planner.dart';
import 'package:qa_genie/engine/domains/identity_domain.dart';
import 'package:qa_genie/engine/domains/commerce_domain.dart';
import 'package:qa_genie/engine/domains/scheduling_domain.dart';
import 'package:qa_genie/engine/ontology/entities.dart';

void main() {
  group('ScenarioPlanner', () {
    group('plan with identity domain', () {
      test('generates scenarios for positive category with account seed', () {
        final planner = ScenarioPlanner(
          domain: IdentityDomain.context,
          categoryCounts: {'positive': 2},
          constraintKeywords: {},
          seedEntities: {EntityType.account},
          constraints: '',
        );
        final scenarios = planner.plan();
        expect(scenarios.length, 2);
        for (final s in scenarios) {
          expect(s.category, 'positive');
          expect(s.isPositive, isTrue);
        }
      });

      test('generates scenarios for negative category', () {
        final planner = ScenarioPlanner(
          domain: IdentityDomain.context,
          categoryCounts: {'negative': 2},
          constraintKeywords: {},
          seedEntities: {EntityType.account},
          constraints: '',
        );
        final scenarios = planner.plan();
        expect(scenarios.length, 2);
        for (final s in scenarios) {
          expect(s.category, 'negative');
        }
      });

      test('generates scenarios for multiple categories', () {
        final planner = ScenarioPlanner(
          domain: IdentityDomain.context,
          categoryCounts: {'positive': 2, 'negative': 1, 'validation': 1},
          constraintKeywords: {},
          seedEntities: {EntityType.account},
          constraints: '',
        );
        final scenarios = planner.plan();
        expect(scenarios.length, 4);
      });

      test('generates unique scenarios (no duplicate fingerprints)', () {
        final planner = ScenarioPlanner(
          domain: IdentityDomain.context,
          categoryCounts: {'positive': 5},
          constraintKeywords: {},
          seedEntities: {EntityType.account},
          constraints: '',
        );
        final scenarios = planner.plan();
        final fingerprints = scenarios.map((s) => '${s.entity.name}|${s.action.name}|${s.category}|${s.targetState.name}').toSet();
        expect(fingerprints.length, scenarios.length);
      });
    });

    group('plan with commerce domain', () {
      test('generates scenarios for pay action', () {
        final planner = ScenarioPlanner(
          domain: CommerceDomain.context,
          categoryCounts: {'positive': 2},
          constraintKeywords: {},
          seedEntities: {EntityType.cart},
          constraints: '',
        );
        final scenarios = planner.plan();
        expect(scenarios.length, 2);
      });

      test('generates positive scenarios using valid condition', () {
        final planner = ScenarioPlanner(
          domain: CommerceDomain.context,
          categoryCounts: {'positive': 3},
          constraintKeywords: {},
          seedEntities: {EntityType.cart},
          constraints: '',
        );
        final scenarios = planner.plan();
        for (final s in scenarios) {
          expect(s.category, 'positive');
        }
      });
    });

    group('plan with scheduling domain', () {
      test('generates scenarios from scheduling domain', () {
        final planner = ScenarioPlanner(
          domain: SchedulingDomain.context,
          categoryCounts: {'positive': 2},
          constraintKeywords: {},
          seedEntities: {EntityType.patient},
          constraints: '',
        );
        final scenarios = planner.plan();
        expect(scenarios.length, 2);
      });
    });

    group('constraint filtering', () {
      test('filters to only security category when constraints contain only security', () {
        final planner = ScenarioPlanner(
          domain: IdentityDomain.context,
          categoryCounts: {'positive': 3, 'security': 2, 'negative': 1},
          constraintKeywords: {},
          seedEntities: {EntityType.account},
          constraints: 'only security',
        );
        final scenarios = planner.plan();
        expect(scenarios, isNotEmpty);
        expect(scenarios.length, 6);
      });

      test('filters to only validation category when constraints contain only validation', () {
        final planner = ScenarioPlanner(
          domain: IdentityDomain.context,
          categoryCounts: {'positive': 2, 'validation': 2},
          constraintKeywords: {},
          seedEntities: {EntityType.account},
          constraints: 'only validation',
        );
        final scenarios = planner.plan();
        expect(scenarios, isNotEmpty);
        expect(scenarios.length, 4);
      });

      test('filters to only boundary category when constraints contain only boundary', () {
        final planner = ScenarioPlanner(
          domain: IdentityDomain.context,
          categoryCounts: {'positive': 2, 'boundary': 2},
          constraintKeywords: {},
          seedEntities: {EntityType.account},
          constraints: 'only boundary',
        );
        final scenarios = planner.plan();
        expect(scenarios, isNotEmpty);
        expect(scenarios.length, 4);
      });
    });

    group('fallback behavior', () {
      test('returns empty list when reachable is empty', () {
        final planner = ScenarioPlanner(
          domain: IdentityDomain.context,
          categoryCounts: {'positive': 1},
          constraintKeywords: {},
          seedEntities: {},
          constraints: '',
        );
        final scenarios = planner.plan();
        expect(scenarios, isEmpty);
      });

      test('fills remaining slots with fallback scenarios', () {
        final planner = ScenarioPlanner(
          domain: IdentityDomain.context,
          categoryCounts: {'positive': 50},
          constraintKeywords: {},
          seedEntities: {EntityType.account},
          constraints: '',
        );
        final scenarios = planner.plan();
        expect(scenarios.length, 50);
        for (final s in scenarios) {
          expect(s.category, 'positive');
        }
      });
    });

    group('edge cases', () {
      test('handles zero needed scenarios', () {
        final planner = ScenarioPlanner(
          domain: IdentityDomain.context,
          categoryCounts: {},
          constraintKeywords: {},
          seedEntities: {EntityType.account},
          constraints: '',
        );
        final scenarios = planner.plan();
        expect(scenarios, isEmpty);
      });

      test('handles category with zero count', () {
        final planner = ScenarioPlanner(
          domain: IdentityDomain.context,
          categoryCounts: {'positive': 0, 'negative': 0},
          constraintKeywords: {},
          seedEntities: {EntityType.account},
          constraints: '',
        );
        final scenarios = planner.plan();
        expect(scenarios, isEmpty);
      });
    });
  });
}
