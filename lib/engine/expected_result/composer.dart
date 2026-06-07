import 'package:qa_genie/engine/business/business_area.dart';

class ExpectedResultComposer {
  static String compose({
    required String outcome,
    required BusinessArea businessArea,
    required List<Map<String, dynamic>> observations,
    required String platform,
    required String module,
    required String feature,
    required String constraints,
  }) {
    if (observations.isEmpty) {
      return _fallbackExpectedResult(feature, platform, constraints);
    }

    // Categorize observations and keep only highest score per category
    final categoryBest = <String, Map<String, dynamic>>{};
    for (final obs in observations) {
      final type = obs['type'] as String;
      final score = obs['score'] as int;
      if (!categoryBest.containsKey(type) ||
          categoryBest[type]!['score'] < score) {
        categoryBest[type] = obs;
      }
    }

    final bestObservations = categoryBest.values.toList();
    bestObservations.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );
    final topTwo = bestObservations.take(2).toList();

    if (topTwo.isEmpty)
      return _fallbackExpectedResult(feature, platform, constraints);
    if (topTwo.length == 1) {
      return _capitalize(topTwo.first['text'] as String);
    }

    final first = _cleanPeriod(_capitalize(topTwo[0]['text'] as String));
    final second = _cleanPeriod(topTwo[1]['text'] as String).toLowerCase();
    return '$first and $second.';
  }

  static String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
  static String _cleanPeriod(String s) => s.replaceAll(RegExp(r'\.$'), '');
  static String _fallbackExpectedResult(
    String feature,
    String platform,
    String constraints,
  ) {
    if (constraints.isNotEmpty) return 'Constraint requirements are satisfied.';
    if (feature.isNotEmpty)
      return 'The $feature process follows expected system rules.';
    if (platform == 'API')
      return 'API responds with appropriate status and data.';
    return 'System processes the request according to defined behavior.';
  }
}
