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

      test('returns all session when constraint is "session"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 3, constraints: 'session', seed: '');
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

      test('returns all positive when constraint is "positive"', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 7, constraints: 'positive', seed: '');
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
      test('returns core default distribution when count is 8', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 8, constraints: '', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts['positive'], 6);
        expect(result.categoryCounts['negative'], 1);
        expect(result.categoryCounts['boundary'], 1);
        expect(result.totalCount, 8);
      });

      test('adjusts positive count upward when totalCount > default sum', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 12, constraints: '', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts['positive'], 10);
        expect(result.categoryCounts['negative'], 1);
        expect(result.categoryCounts['boundary'], 1);
        expect(result.totalCount, 12);
      });

      test('uses security edge when constraints contain security', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 8, constraints: 'security', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts.containsKey('security'), isTrue);
        expect(result.categoryCounts.containsKey('boundary'), isFalse);
        expect(result.riskFocus, ['HIGH']);
      });

      test('uses boundary edge when constraints do not contain security', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 8, constraints: '', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts.containsKey('boundary'), isTrue);
        expect(result.categoryCounts.containsKey('security'), isFalse);
      });
    });

    group('default plan with pro mode', () {
      test('returns pro default distribution when count is 16', () {
        final planner = CoveragePlanner(mode: GenerationMode.pro, totalCount: 16, constraints: '', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts['positive'], 10);
        expect(result.categoryCounts['negative'], 4);
        expect(result.categoryCounts['boundary'], 2);
        expect(result.totalCount, 16);
      });
    });

    group('constraint overrides in default plan', () {
      test('returns all security when constraints only contain security', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 6, constraints: 'security', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'security': 6});
      });

      test('returns all negative when constraints only contain negative', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 5, constraints: 'negative', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'negative': 5});
      });

      test('returns all validation when constraints only contain validation', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 4, constraints: 'validation', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'validation': 4});
      });

      test('returns all boundary when constraints only contain boundary', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 3, constraints: 'boundary', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'boundary': 3});
      });

      test('returns all session when constraints only contain session', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 3, constraints: 'session', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts, {'session': 3});
      });

      test('uses core default when multiple constraint keywords present', () {
        final planner = CoveragePlanner(mode: GenerationMode.core, totalCount: 8, constraints: 'security negative', seed: '');
        final result = planner.plan();
        expect(result.categoryCounts['positive'], 6);
        expect(result.categoryCounts['negative'], 1);
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
