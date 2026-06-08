/// Constraint types that override default coverage.
enum ConstraintIntent {
  security,
  validation,
  boundary,
  positiveOnly,
  negativeOnly,
  positiveAndNegative,
  sessionOnly,
  oauthOnly,
  none,
}

/// Parses a constraint string and extracts intent and relevant keywords.
class ConstraintParserResult {
  final ConstraintIntent intent;
  final Set<String> keywords; // e.g., {"insurance", "expired", "token"}

  const ConstraintParserResult({required this.intent, required this.keywords});
}

/// Simple parser for constraints (to be used by ConstraintParser later).
class ConstraintUtils {
  static ConstraintIntent detectIntent(String constraints) {
    final lower = constraints.toLowerCase();
    if (lower.contains('only security') ||
        lower.contains('security only') ||
        (lower.contains('security') &&
            !lower.contains('positive') &&
            !lower.contains('negative'))) {
      return ConstraintIntent.security;
    }
    if (lower.contains('only validation') ||
        lower.contains('validation only')) {
      return ConstraintIntent.validation;
    }
    if (lower.contains('only boundary') || lower.contains('boundary only')) {
      return ConstraintIntent.boundary;
    }
    if (lower.contains('only positive') || lower.contains('positive only')) {
      return ConstraintIntent.positiveOnly;
    }
    if (lower.contains('only negative') || lower.contains('negative only')) {
      return ConstraintIntent.negativeOnly;
    }
    if (lower.contains('positive and negative') ||
        (lower.contains('positive') && lower.contains('negative'))) {
      return ConstraintIntent.positiveAndNegative;
    }
    if (lower.contains('only session') ||
        lower.contains('session only') ||
        (lower.contains('session') && !lower.contains('expiry'))) {
      return ConstraintIntent.sessionOnly;
    }
    if (lower.contains('oauth') || lower.contains('social login')) {
      return ConstraintIntent.oauthOnly;
    }
    return ConstraintIntent.none;
  }

  static Set<String> extractKeywords(String constraints) {
    final lower = constraints.toLowerCase();
    final words = lower.split(RegExp(r'\s+'));
    final stopWords = {
      'only',
      'generate',
      'test',
      'cases',
      'include',
      'focus',
      'on',
      'and',
      'or',
      'for',
      'with',
    };
    return words
        .where((w) => !stopWords.contains(w) && w.length > 2)
        .map((w) => w.replaceAll(RegExp(r'[^\w]'), ''))
        .toSet();
  }
}
