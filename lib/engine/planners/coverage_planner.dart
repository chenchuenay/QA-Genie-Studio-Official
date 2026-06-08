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

    // Default category distribution according to user specification
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
    final securityFocused = constraints.toLowerCase().contains('security');
    final negativeFocused = constraints.toLowerCase().contains('negative');
    final sessionFocused = constraints.toLowerCase().contains('session');
    final validationFocused = constraints.toLowerCase().contains('validation');
    final boundaryFocused = constraints.toLowerCase().contains('boundary');

    Map<String, int> categoryCounts = {};

    // Constraint overrides (if only one type is requested, honor it)
    if (securityFocused &&
        !negativeFocused &&
        !sessionFocused &&
        !validationFocused &&
        !boundaryFocused) {
      categoryCounts = {'security': totalCount};
    } else if (negativeFocused &&
        !securityFocused &&
        !sessionFocused &&
        !validationFocused &&
        !boundaryFocused) {
      categoryCounts = {'negative': totalCount};
    } else if (validationFocused &&
        !securityFocused &&
        !negativeFocused &&
        !sessionFocused &&
        !boundaryFocused) {
      categoryCounts = {'validation': totalCount};
    } else if (boundaryFocused &&
        !securityFocused &&
        !negativeFocused &&
        !sessionFocused &&
        !validationFocused) {
      categoryCounts = {'boundary': totalCount};
    } else if (sessionFocused &&
        !securityFocused &&
        !negativeFocused &&
        !validationFocused &&
        !boundaryFocused) {
      categoryCounts = {'session': totalCount};
    } else {
      // Default distribution based on mode (Core vs Pro)
      if (mode == GenerationMode.core) {
        // Core: 6 Positive, 1 Negative, 1 Edge (boundary or security)
        categoryCounts = {'positive': 6, 'negative': 1};
        // If constraints mention security, use security as the edge; otherwise boundary
        if (constraints.toLowerCase().contains('security')) {
          categoryCounts['security'] = 1;
        } else {
          categoryCounts['boundary'] = 1;
        }
      } else {
        // PRO: 10 Positive, 4 Negative, 2 Edge (boundary or security)
        categoryCounts = {'positive': 10, 'negative': 4};
        if (constraints.toLowerCase().contains('security')) {
          categoryCounts['security'] = 2;
        } else {
          categoryCounts['boundary'] = 2;
        }
      }
    }

    // Remove any zero counts (optional but cleaner)
    categoryCounts.removeWhere((key, value) => value <= 0);

    // Ensure total matches totalCount (adjust positive up/down if necessary)
    int sum = categoryCounts.values.reduce((a, b) => a + b);
    if (sum != totalCount) {
      int diff = totalCount - sum;
      categoryCounts['positive'] = (categoryCounts['positive'] ?? 0) + diff;
      // Clamp positive to non-negative
      if (categoryCounts['positive']! < 0) {
        categoryCounts['positive'] = 0;
        // If still not matching, fallback to all positive (should not happen)
        if (categoryCounts.values.reduce((a, b) => a + b) != totalCount) {
          categoryCounts = {'positive': totalCount};
        }
      }
    }

    // Final cleanup: remove zeros again after adjustment
    categoryCounts.removeWhere((key, value) => value <= 0);

    return CoverageRequest(
      totalCount: totalCount,
      categoryCounts: categoryCounts,
      riskFocus: securityFocused ? ['HIGH'] : [],
    );
  }
}
