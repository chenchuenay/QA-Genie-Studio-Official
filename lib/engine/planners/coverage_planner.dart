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
