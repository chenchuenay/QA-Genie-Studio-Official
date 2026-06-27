import 'package:qa_genie/domain/enums/generation_mode.dart';

class CoverageRequest {
  final int totalCount;
  final Map<String, int> categoryCounts;
  final List<String> riskFocus;

  const CoverageRequest({
    required this.totalCount,
    required this.categoryCounts,
    this.riskFocus = const [],
  });
}

class CoveragePlanner {
  final GenerationMode mode;
  final int totalCount;
  final String constraints;
  final String seed;

  CoveragePlanner({
    required this.mode,
    required this.totalCount,
    required this.constraints,
    required this.seed,
  });

  CoverageRequest plan() {
    // Edge cases: totalCount must be positive
    if (totalCount <= 0) {
      return CoverageRequest(totalCount: 0, categoryCounts: {}, riskFocus: []);
    }

    // If totalCount is 1, simplest is a single positive case
    if (totalCount == 1) {
      return CoverageRequest(
        totalCount: 1,
        categoryCounts: {'positive': 1},
        riskFocus: [],
      );
    }

    // If constraints are present, try to detect intent
    if (constraints.trim().isNotEmpty) {
      final intent = _parseConstraintIntent(constraints.toLowerCase());
      if (intent != null) {
        return _planForIntent(intent);
      }
    }

    // Default category distribution according to member specification
    return _defaultPlan();
  }

  String? _parseConstraintIntent(String c) {
    // Exact overrides — only "only X" triggers hard override
    if (c.contains('only security')) return 'security';
    if (c.contains('only validation')) return 'validation';
    if (c.contains('only boundary')) return 'boundary';
    if (c.contains('only session')) return 'session';
    if (c.contains('only positive')) return 'positive';
    if (c.contains('only negative')) return 'negative';
    if (c.contains('oauth') || c.contains('social login')) return 'oauth';
    if (c.contains('expiry') || c.contains('concurrent'))
      return 'session_expiry';
    // Mixed positive+negative
    if (c.contains('positive and negative')) return 'positive_negative';
    return null;
  }

  CoverageRequest _planForIntent(String intent) {
    switch (intent) {
      case 'security':
        return CoverageRequest(
          totalCount: totalCount,
          categoryCounts: {'security': totalCount},
          riskFocus: ['HIGH'],
        );
      case 'validation':
        return CoverageRequest(
          totalCount: totalCount,
          categoryCounts: {'validation': totalCount},
        );
      case 'boundary':
        return CoverageRequest(
          totalCount: totalCount,
          categoryCounts: {'boundary': totalCount},
        );
      case 'session':
      case 'session_expiry':
        return CoverageRequest(
          totalCount: totalCount,
          categoryCounts: {'session': totalCount},
          riskFocus: ['HIGH'],
        );
      case 'positive':
        return CoverageRequest(
          totalCount: totalCount,
          categoryCounts: {'positive': totalCount},
        );
      case 'negative':
        return CoverageRequest(
          totalCount: totalCount,
          categoryCounts: {'negative': totalCount},
        );
      case 'positive_negative':
        final pos = (totalCount / 2).ceil();
        final neg = totalCount - pos;
        return CoverageRequest(
          totalCount: totalCount,
          categoryCounts: {'positive': pos, 'negative': neg},
        );
      case 'oauth':
        return CoverageRequest(
          totalCount: totalCount,
          categoryCounts: {'positive': totalCount},
        );
      default:
        return _defaultPlan();
    }
  }

  CoverageRequest _defaultPlan() {
    final nonHappyCount = (totalCount * 30 + 50) ~/ 100;
    final happyCount = totalCount - nonHappyCount;
    final categoryCounts = <String, int>{'positive': happyCount};

    if (nonHappyCount > 0) {
      const cats = ['negative', 'boundary', 'validation', 'security', 'session'];
      final base = nonHappyCount ~/ 5;
      final rem = nonHappyCount % 5;
      for (int i = 0; i < cats.length; i++) {
        categoryCounts[cats[i]] = base + (i < rem ? 1 : 0);
      }
    }

    categoryCounts.removeWhere((key, v) => v <= 0);

    final sum = categoryCounts.values.reduce((a, b) => a + b);
    if (sum != totalCount) {
      categoryCounts['positive'] = (categoryCounts['positive'] ?? 0) + (totalCount - sum);
    }
    categoryCounts.removeWhere((key, v) => v <= 0);

    return CoverageRequest(
      totalCount: totalCount,
      categoryCounts: categoryCounts,
      riskFocus: [],
    );
  }
}
