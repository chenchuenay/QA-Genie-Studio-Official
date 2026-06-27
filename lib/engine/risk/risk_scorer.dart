import 'package:qa_genie/domain/entities/finalized_test_case.dart';

enum RiskTier { mustTest, shouldTest, optional }

class RiskScorer {
  const RiskScorer._();

  static const int _weightSecurity = 3;
  static const int _weightNegative = 2;
  static const int _weightHigh = 3;
  static const int _weightMedium = 1;
  static const int _weightFailed = 3;
  static const int _weightUnexecuted = 1;

  static const int _thresholdMustTest = 6;
  static const int _thresholdShouldTest = 3;

  static Map<String, int> score(List<FinalizedTestCase> cases) {
    final result = <String, int>{};
    for (final tc in cases) {
      int s = 0;
      final type = tc.type.toLowerCase().trim();
      if (type == 'security') s += _weightSecurity;
      if (type == 'negative') s += _weightNegative;

      final priority = tc.priority.toLowerCase().trim();
      if (priority == 'high') s += _weightHigh;
      if (priority == 'medium') s += _weightMedium;

      final status = tc.status.toLowerCase().trim();
      if (status == 'failed') s += _weightFailed;
      if (status == 'not executed' || status == 'unexecuted' || status.isEmpty) {
        s += _weightUnexecuted;
      }

      result[tc.id] = s;
    }
    return result;
  }

  static RiskTier tier(int score) {
    if (score >= _thresholdMustTest) return RiskTier.mustTest;
    if (score >= _thresholdShouldTest) return RiskTier.shouldTest;
    return RiskTier.optional;
  }

  static String label(int score) {
    switch (tier(score)) {
      case RiskTier.mustTest: return 'Must Test';
      case RiskTier.shouldTest: return 'Should Test';
      case RiskTier.optional: return 'Optional';
    }
  }

  static String icon(int score) {
    switch (tier(score)) {
      case RiskTier.mustTest: return '🛑';
      case RiskTier.shouldTest: return '⚠️';
      case RiskTier.optional: return '✅';
    }
  }
}
