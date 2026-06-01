import 'package:qa_genie/engine/knowledge/intent_registry.dart';

class IntentRecovery {
  /// Attempts to recover an intent ID from a test case's title, category, and expected result.
  /// If no confident match, returns '__unknown__' (honest fallback).
  static String recoverIntent({
    required String title,
    required String category,
    required String expectedResult,
    required String businessArea,
  }) {
    final combined = '$title $expectedResult'.toLowerCase();
    final candidates = IntentRegistry.findByCategory(category)
        .where((i) => i.businessArea == businessArea)
        .toList();

    // Score each candidate by keyword matches
    IntentDefinition? bestMatch;
    int bestScore = 0;
    for (final candidate in candidates) {
      int score = 0;
      for (final kw in candidate.keywords) {
        if (combined.contains(kw)) score++;
      }
      if (score > bestScore && score > 0) {
        bestScore = score;
        bestMatch = candidate;
      }
    }
    if (bestMatch != null) return bestMatch.id;
    // Fix #11: Return __unknown__ instead of fabricating a generic intent
    return '__unknown__';
  }
}