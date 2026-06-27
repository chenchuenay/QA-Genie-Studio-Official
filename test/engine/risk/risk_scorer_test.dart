import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/risk/risk_scorer.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

FinalizedTestCase _tc({
  String id = 'TC1',
  String type = 'functional',
  String priority = 'Low',
  String status = 'Pass',
}) {
  return FinalizedTestCase(
    id: id,
    title: 'Test $id',
    type: type,
    priority: priority,
    status: status,
    steps: [TestStep(action: 'Step 1')],
    preconditions: [],
    testData: '',
    expectedResult: 'Expected',
    module: 'TestModule',
    feature: 'TestFeature',
    platform: 'WEB',
    source: CaseSource.ai,
  );
}

void main() {
  group('RiskScorer.score', () {
    test('returns empty map for empty list', () {
      expect(RiskScorer.score([]), isEmpty);
    });

    test('default (Low + Pass) scores 0', () {
      final result = RiskScorer.score([_tc()]);
      expect(result['TC1'], equals(0));
    });

    test('security adds weight 3', () {
      final result = RiskScorer.score([_tc(type: 'security')]);
      expect(result['TC1'], equals(3));
    });

    test('negative adds weight 2', () {
      final result = RiskScorer.score([_tc(type: 'negative')]);
      expect(result['TC1'], equals(2));
    });

    test('high priority adds weight 3', () {
      final result = RiskScorer.score([_tc(priority: 'High')]);
      expect(result['TC1'], equals(3));
    });

    test('medium priority adds weight 1', () {
      final result = RiskScorer.score([_tc(priority: 'Medium')]);
      expect(result['TC1'], equals(1));
    });

    test('low priority no bonus', () {
      final result = RiskScorer.score([_tc(priority: 'Low')]);
      expect(result['TC1'], equals(0));
    });

    test('failed status adds weight 3', () {
      final result = RiskScorer.score([_tc(status: 'Failed')]);
      expect(result['TC1'], equals(3));
    });

    test('pass status no bonus', () {
      final result = RiskScorer.score([_tc(status: 'Pass')]);
      expect(result['TC1'], equals(0));
    });

    test('multi-keyword stacking', () {
      final result = RiskScorer.score([
        _tc(id: 'TC1', type: 'security', priority: 'High', status: 'Failed'),
      ]);
      // security=3, high=3, failed=3, no unexecuted bonus since status is Failed
      expect(result['TC1'], equals(9));
    });

    test('security + negative + high + not executed', () {
      final result = RiskScorer.score([
        _tc(id: 'TC1', type: 'security', priority: 'High', status: 'Not Executed'),
      ]);
      // security=3, high=3, unexecuted=1
      expect(result['TC1'], equals(7));
    });

    test('handles each case independently', () {
      final result = RiskScorer.score([
        _tc(id: 'TC1', type: 'functional', priority: 'Low', status: 'Pass'),
        _tc(id: 'TC2', type: 'security', priority: 'High', status: 'Failed'),
      ]);
      expect(result['TC1'], equals(0));
      expect(result['TC2'], equals(9));
    });

    test('empty status treated as not executed', () {
      final result = RiskScorer.score([_tc(status: '')]);
      expect(result['TC1'], equals(1));
    });
  });

  group('RiskScorer.tier', () {
    test('score >= 6 is mustTest', () {
      expect(RiskScorer.tier(6), equals(RiskTier.mustTest));
      expect(RiskScorer.tier(9), equals(RiskTier.mustTest));
    });

    test('score 3-5 is shouldTest', () {
      expect(RiskScorer.tier(3), equals(RiskTier.shouldTest));
      expect(RiskScorer.tier(4), equals(RiskTier.shouldTest));
      expect(RiskScorer.tier(5), equals(RiskTier.shouldTest));
    });

    test('score 0-2 is optional', () {
      expect(RiskScorer.tier(0), equals(RiskTier.optional));
      expect(RiskScorer.tier(1), equals(RiskTier.optional));
      expect(RiskScorer.tier(2), equals(RiskTier.optional));
    });

    test('boundary at 6', () {
      expect(RiskScorer.tier(5), equals(RiskTier.shouldTest));
      expect(RiskScorer.tier(6), equals(RiskTier.mustTest));
    });
  });

  group('RiskScorer.label', () {
    test('return correct labels', () {
      expect(RiskScorer.label(7), equals('Must Test'));
      expect(RiskScorer.label(4), equals('Should Test'));
      expect(RiskScorer.label(1), equals('Optional'));
    });
  });

  group('RiskScorer.icon', () {
    test('return correct icons', () {
      expect(RiskScorer.icon(7), equals('🛑'));
      expect(RiskScorer.icon(4), equals('⚠️'));
      expect(RiskScorer.icon(1), equals('✅'));
    });
  });
}
