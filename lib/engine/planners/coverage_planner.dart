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
  final String domain;

  CoveragePlanner({
    required this.mode,
    required this.totalCount,
    required this.constraints,
    required this.seed,
    this.domain = 'general',
  });

  CoverageRequest plan() {
    if (totalCount <= 0) {
      return CoverageRequest(totalCount: 0, categoryCounts: {}, riskFocus: []);
    }

    if (totalCount == 1) {
      return CoverageRequest(
        totalCount: 1,
        categoryCounts: {'positive': 1},
        riskFocus: [],
      );
    }

    if (constraints.trim().isNotEmpty) {
      final intent = _parseConstraintIntent(constraints.toLowerCase());
      if (intent != null) {
        return _planForIntent(intent);
      }
    }

    return _defaultPlan();
  }

  String? _parseConstraintIntent(String c) {
    if (c.contains('only security')) return 'security';
    if (c.contains('only validation')) return 'validation';
    if (c.contains('only boundary')) return 'boundary';
    if (c.contains('only session')) return 'session';
    if (c.contains('only positive')) return 'positive';
    if (c.contains('only negative')) return 'negative';
    if (c.contains('expiry') || c.contains('concurrent'))
      return 'session_expiry';
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
      default:
        return _defaultPlan();
    }
  }

  CoverageRequest _defaultPlan() {
    final nonHappyPercent = _domainNonHappyPercent();
    final nonHappyCount = (totalCount * nonHappyPercent + 50) ~/ 100;
    final happyCount = totalCount - nonHappyCount;
    final categoryCounts = <String, int>{'positive': happyCount};

    if (nonHappyCount > 0) {
      final weighted = _domainCategoryWeights();
      final totalWeight = weighted.values.fold(0, (a, b) => a + b);
      final catKeys = weighted.keys.toList();
      final counts = <String, int>{};
      final remainders = <String, double>{};
      int totalAssigned = 0;
      for (final cat in catKeys) {
        final exact = nonHappyCount * weighted[cat]! / totalWeight;
        final floorCount = exact.floor();
        counts[cat] = floorCount;
        totalAssigned += floorCount;
        remainders[cat] = exact - floorCount;
      }
      int remaining = nonHappyCount - totalAssigned;
      final sortedCats = catKeys.toList()
        ..sort((a, b) => remainders[b]!.compareTo(remainders[a]!));
      for (final cat in sortedCats) {
        if (remaining <= 0) break;
        counts[cat] = counts[cat]! + 1;
        remaining--;
      }
      for (final entry in counts.entries) {
        if (entry.value > 0) {
          categoryCounts[entry.key] = entry.value;
        }
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

  int _domainNonHappyPercent() {
    switch (domain) {
      case 'oauthSocial':
      case 'samlSso':
        return 50;
      case 'apiKey':
        return 40;
      default:
        return 40;
    }
  }

  Map<String, int> _domainCategoryWeights() {
    switch (domain) {
      case 'oauthSocial':
      case 'samlSso':
        return {'security': 3, 'session': 2, 'negative': 2, 'boundary': 1, 'validation': 1};
      case 'apiKey':
        return {'negative': 3, 'boundary': 2, 'security': 2, 'validation': 1, 'session': 1};
      default:
        return {'negative': 1, 'boundary': 1, 'validation': 1, 'security': 1, 'session': 1};
    }
  }
}
