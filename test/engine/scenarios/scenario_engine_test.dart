import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/scenarios/scenario_engine.dart';
import 'package:qa_genie/engine/business/business_area.dart';

void main() {
  group('ScenarioEngine', () {
    test('generateAssignments returns assignments for unrecognized area (uses fallback)', () {
      final engine = ScenarioEngine('test_seed');
      final result = engine.generateAssignments(
        categoryCounts: {'positive': 1},
        businessArea: const BusinessArea(id: 'unknown', domain: 'unknown', riskProfile: 'low'),
      );
      expect(result, isNotEmpty);
    });

    test('generateAssignments returns assignments for auth-like business area', () {
      final engine = ScenarioEngine('test_seed');
      final result = engine.generateAssignments(
        categoryCounts: {'positive': 1},
        businessArea: const BusinessArea(id: 'authentication', domain: 'security', riskProfile: 'high'),
      );
      expect(result, isNotEmpty);
    });

    test('generateAssignments handles ecommerce business area', () {
      final engine = ScenarioEngine('seed');
      final result = engine.generateAssignments(
        categoryCounts: {'positive': 2, 'negative': 1},
        businessArea: const BusinessArea(id: 'ecommerce', domain: 'transaction', riskProfile: 'medium'),
      );
      expect(result, isNotEmpty);
    });

    test('generateAssignments respects category count limits', () {
      final engine = ScenarioEngine('seed');
      final result = engine.generateAssignments(
        categoryCounts: {'positive': 1},
        businessArea: const BusinessArea(id: 'authentication', domain: 'security', riskProfile: 'high'),
      );
      expect(result.length, equals(1));
    });

    test('generateAssignments returns scenarios with correct indices', () {
      final engine = ScenarioEngine('seed');
      final result = engine.generateAssignments(
        categoryCounts: {'positive': 3},
        businessArea: const BusinessArea(id: 'authentication', domain: 'security', riskProfile: 'high'),
      );
      expect(result.length, equals(3));
      for (int i = 0; i < result.length; i++) {
        expect(result[i].index, equals(i));
      }
    });

    test('generateAssignments uses fallback for empty categories', () {
      final engine = ScenarioEngine('seed');
      final result = engine.generateAssignments(
        categoryCounts: {'nonexistent': 2},
        businessArea: const BusinessArea(id: 'authentication', domain: 'security', riskProfile: 'high'),
      );
      expect(result.length, equals(2));
    });
  });
}
