import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/planners/coverage_planner.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';

void main() {
  group('CoveragePlanner', () {
    group('plan with edge cases', () {
      test('returns empty coverage when totalCount is zero', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 0, constraints: '', seed: '');
        final result = planner.plan();
        expect(result.totalCount, 0);
        expect(result.categoryCounts, isEmpty);
      });

      test('returns empty coverage when totalCount is negative', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: -5, constraints: '', seed: '');
        final result = planner.plan();
        expect(result.totalCount, 0);
        expect(result.categoryCounts, isEmpty);
      });

      test('returns single positive when totalCount is 1', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 1, constraints: '', seed: '');
        final result = planner.plan();
        expect(result.totalCount, 1);
        expect(result.categoryCounts, {'positive': 1});
      });
    });

    group('plan with constraint intent overrides', () {
      test('returns all security when constraint is "only security"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 5, constraints: 'only security', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'security': 5});
        expect(result.riskFocus, ['HIGH']);
      });

      test('returns all validation when constraint is "only validation"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 3, constraints: 'only validation', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'validation': 3});
      });

      test('returns all boundary when constraint is "only boundary"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 4, constraints: 'only boundary', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'boundary': 4});
      });

      test('returns all session when constraint is "only session"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 3, constraints: 'only session', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'session': 3});
        expect(result.riskFocus, ['HIGH']);
      });

      test('returns all session when constraint contains expiry', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 2, constraints: 'expiry token', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'session': 2});
      });

      test('returns all session when constraint contains concurrent', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 2, constraints: 'concurrent login', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'session': 2});
      });

      test('returns all positive when constraint is "only positive"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 7, constraints: 'only positive', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'positive': 7});
      });

      test('returns all negative when constraint is "only negative"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 5, constraints: 'only negative', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'negative': 5});
      });

      test('returns mixed positive and negative when constraint includes both', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 5, constraints: 'positive and negative', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts['positive'], 3);
        expect(result.categoryCounts['negative'], 2);
        expect(result.totalCount, 5);
      });

      test('returns all positive for oauth constraint', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 4, constraints: 'oauth', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'positive': 4});
      });

      test('returns all positive for social login constraint', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 3, constraints: 'social login', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'positive': 3});
      });
    });

    group('default plan with core mode', () {
      test('returns 70/30 distribution when count is 8', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 8, constraints: '', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts['positive'], 6);
        expect(result.categoryCounts['negative'], 1);
        expect(result.categoryCounts['boundary'], 1);
        expect(result.totalCount, 8);
      });

      test('adjusts counts proportionally when totalCount > 10', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 12, constraints: '', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts['positive'], 8);
        expect(result.categoryCounts['negative'], 1);
        expect(result.categoryCounts['boundary'], 1);
        expect(result.categoryCounts['validation'], 1);
        expect(result.categoryCounts['security'], 1);
        expect(result.totalCount, 12);
      });

      test('has positive as the majority category in default plan', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 10, constraints: '', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts['positive'], 7);
        expect(result.categoryCounts.containsKey('negative'), isTrue);
        expect(result.categoryCounts.containsKey('boundary'), isTrue);
        expect(result.totalCount, 10);
      });
    });

    group('default plan with pro mode', () {
      test('returns 70/30 pro distribution when count is 16', () {
        final planner = CoveragePlanner(mode: GenerationMode.pro, totalCount: 16, constraints: '', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts['positive'], 11);
        expect(result.categoryCounts['negative'], 1);
        expect(result.categoryCounts['boundary'], 1);
        expect(result.categoryCounts['validation'], 1);
        expect(result.categoryCounts['security'], 1);
        expect(result.categoryCounts['session'], 1);
        expect(result.totalCount, 16);
      });
    });

    group('only-X overrides in plan', () {
      test('returns all security when constraint is "only security"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 6, constraints: 'only security', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'security': 6});
      });

      test('returns all negative when constraint is "only negative"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 5, constraints: 'only negative', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'negative': 5});
      });

      test('returns all validation when constraint is "only validation"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 4, constraints: 'only validation', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'validation': 4});
      });

      test('returns all boundary when constraint is "only boundary"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 3, constraints: 'only boundary', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'boundary': 3});
      });

      test('returns all session when constraint is "only session"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 3, constraints: 'only session', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'session': 3});
      });

      test('vague keywords fall back to default 70/30 distribution', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 10, constraints: 'security negative', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts['positive'], 7);
        expect(result.totalCount, 10);
      });
    });

    test('CoverageRequest constructor stores fields correctly', () {
      final req = CoverageRequest(totalCount: 10, categoryCounts: {'a': 5, 'b': 5}, riskFocus: ['HIGH']);
      expect(req.totalCount, 10);
      expect(req.categoryCounts, {'a': 5, 'b': 5});
      expect(req.riskFocus, ['HIGH']);
    });

    test('CoverageRequest defaults riskFocus to empty', () {
      final req = CoverageRequest(totalCount: 3, categoryCounts: {'x': 3});
      expect(req.riskFocus, isEmpty);
    });
  });
}
