import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/validators/coverage_validator.dart';
import 'package:qa_genie/engine/models/scenario.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/states.dart';

Scenario _scenario(String category) {
  return Scenario(
    entity: EntityType.account,
    action: ActionType.login,
    targetState: StateType.authenticated,
    category: category,
  );
}

void main() {
  group('CoverageValidator', () {
    test('returns true when constraints are satisfied', () {
      final scenarios = [
        _scenario('positive'),
        _scenario('positive'),
        _scenario('negative'),
      ];
      expect(
        CoverageValidator.satisfiesConstraints(
          scenarios,
          {'positive': 2, 'negative': 1},
        ),
        isTrue,
      );
    });

    test('returns false when constraints are not satisfied', () {
      final scenarios = [
        _scenario('positive'),
      ];
      expect(
        CoverageValidator.satisfiesConstraints(
          scenarios,
          {'positive': 2},
        ),
        isFalse,
      );
    });

    test('returns true when there are more than required', () {
      final scenarios = [
        _scenario('positive'),
        _scenario('positive'),
        _scenario('positive'),
      ];
      expect(
        CoverageValidator.satisfiesConstraints(
          scenarios,
          {'positive': 2},
        ),
        isTrue,
      );
    });

    test('returns true for empty required counts', () {
      expect(
        CoverageValidator.satisfiesConstraints(
          [_scenario('positive')],
          {},
        ),
        isTrue,
      );
    });

    test('returns false when category missing entirely', () {
      expect(
        CoverageValidator.satisfiesConstraints(
          [_scenario('positive')],
          {'negative': 1},
        ),
        isFalse,
      );
    });

    test('returns true for empty scenarios with empty requirements', () {
      expect(
        CoverageValidator.satisfiesConstraints([], {}),
        isTrue,
      );
    });

    test('returns false for empty scenarios with requirements', () {
      expect(
        CoverageValidator.satisfiesConstraints([], {'positive': 1}),
        isFalse,
      );
    });
  });
}
