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
    // If constraints are present, try to detect intent
    if (constraints.trim().isNotEmpty) {
      final intent = _parseConstraintIntent(constraints.toLowerCase());
      if (intent != null) {
        return _planForIntent(intent);
      }
    }

    // Default category distribution (80/20, with mixed categories)
    return _defaultPlan();
  }

  String? _parseConstraintIntent(String c) {
    // Exact overrides
    if (c.contains('only security') || c == 'security') return 'security';
    if (c.contains('only validation') || c == 'validation') return 'validation';
    if (c.contains('only boundary') || c == 'boundary') return 'boundary';
    if (c.contains('only session') || c == 'session') return 'session';
    if (c.contains('only positive') || c == 'positive') return 'positive';
    if (c.contains('only negative') || c == 'negative') return 'negative';
    if (c.contains('oauth') || c.contains('social login')) return 'oauth';
    if (c.contains('expiry') || c.contains('concurrent'))
      return 'session_expiry';
    // Mixed positive+negative
    if (c.contains('positive and negative')) return 'positive_negative';
    // Default fallback – not overriding
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
        // For OAuth, we still use positive category but the outcome will be social_login
        return CoverageRequest(
          totalCount: totalCount,
          categoryCounts: {'positive': totalCount},
        );
      default:
        return _defaultPlan();
    }
  }

  CoverageRequest _defaultPlan() {
    bool securityFocused = constraints.toLowerCase().contains('security');
    bool negativeFocused = constraints.toLowerCase().contains('negative');
    bool sessionFocused = constraints.toLowerCase().contains('session');

    Map<String, int> categoryCounts = {};

    if (securityFocused) {
      categoryCounts = {
        'positive': (totalCount * 0.2).floor(),
        'security': (totalCount * 0.6).floor(),
        'negative': (totalCount * 0.2).floor(),
      };
    } else if (negativeFocused) {
      categoryCounts = {
        'positive': (totalCount * 0.5).floor(),
        'negative': (totalCount * 0.3).floor(),
        'validation': (totalCount * 0.2).floor(),
      };
    } else if (sessionFocused) {
      categoryCounts = {
        'positive': (totalCount * 0.6).floor(),
        'session': (totalCount * 0.4).floor(),
      };
    } else {
      int positive = (totalCount * 0.8).floor();
      int others = totalCount - positive;
      categoryCounts = {
        'positive': positive,
        'negative': (others * 0.5).ceil(),
        'validation': (others * 0.3).ceil(),
        'boundary': (others * 0.2).ceil(),
      };
    }

    // Minimum guarantees for Core/Pro
    if (mode == GenerationMode.core) {
      categoryCounts['negative'] = (categoryCounts['negative'] ?? 0).clamp(
        1,
        totalCount,
      );
      categoryCounts['validation'] = (categoryCounts['validation'] ?? 0).clamp(
        1,
        totalCount,
      );
    } else if (mode == GenerationMode.pro) {
      categoryCounts['negative'] = (categoryCounts['negative'] ?? 0).clamp(
        1,
        totalCount,
      );
      categoryCounts['validation'] = (categoryCounts['validation'] ?? 0).clamp(
        1,
        totalCount,
      );
      categoryCounts['boundary'] = (categoryCounts['boundary'] ?? 0).clamp(
        1,
        totalCount,
      );
    }

    int sum = categoryCounts.values.reduce((a, b) => a + b);
    if (sum < totalCount)
      categoryCounts['positive'] =
          (categoryCounts['positive'] ?? 0) + (totalCount - sum);
    if (sum > totalCount)
      categoryCounts['positive'] =
          (categoryCounts['positive'] ?? 0) - (sum - totalCount);

    return CoverageRequest(
      totalCount: totalCount,
      categoryCounts: categoryCounts,
      riskFocus: securityFocused ? ['HIGH'] : [],
    );
  }
}
