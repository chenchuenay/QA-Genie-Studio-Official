import '../models/scenario.dart';

class CoverageValidator {
  static bool satisfiesConstraints(
    List<Scenario> scenarios,
    Map<String, int> requiredCounts,
  ) {
    final actual = <String, int>{};
    for (final s in scenarios) {
      actual[s.category] = (actual[s.category] ?? 0) + 1;
    }
    for (final entry in requiredCounts.entries) {
      if ((actual[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }
}
