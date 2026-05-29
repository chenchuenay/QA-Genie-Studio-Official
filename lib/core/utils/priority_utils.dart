// ============================================================

// FILE: lib/core/utils/priority_utils.dart

// ============================================================

class PriorityUtils {
  const PriorityUtils._();

  static const List<String> allowed = ['High', 'Medium', 'Low'];

  // ==========================================================

  // AI PRIORITY NORMALIZATION

  // ==========================================================

  /// IMPORTANT:

  /// We TRUST AI priority first.

  ///

  /// This utility ONLY normalizes:

  /// - malformed AI values

  /// - fallback generated cases

  /// - repair-generated cases

  ///

  /// We DO NOT aggressively override AI intent.

  static String normalize(String? value) {
    if (value == null || value.trim().isEmpty) {
      return PriorityConstants.medium;
    }

    final v = value.trim().toLowerCase();

    // --------------------------------------------------------

    // HIGH

    // --------------------------------------------------------

    if (v == 'high' ||
        v == 'critical' ||
        v == 'p0' ||
        v == 'highest' ||
        v == 'blocker' ||
        v == 'sev1' ||
        v == '1') {
      return PriorityConstants.high;
    }

    // --------------------------------------------------------

    // MEDIUM

    // --------------------------------------------------------

    if (v == 'medium' ||
        v == 'moderate' ||
        v == 'major' ||
        v == 'p1' ||
        v == '2') {
      return PriorityConstants.medium;
    }

    // --------------------------------------------------------

    // LOW

    // --------------------------------------------------------

    if (v == 'low' || v == 'minor' || v == 'trivial' || v == 'p2' || v == '3') {
      return PriorityConstants.low;
    }

    // --------------------------------------------------------

    // SAFE DEFAULT

    // --------------------------------------------------------

    return PriorityConstants.medium;
  }

  // ==========================================================

  // FALLBACK PRIORITY ASSIGNMENT

  // ==========================================================

  /// Used ONLY when AI completely misses priority.

  static String fallback({
    required String category,

    required String title,

    required String feature,
  }) {
    final text = '$category $title $feature'.toLowerCase();

    // --------------------------------------------------------

    // HIGH-RISK AREAS

    // --------------------------------------------------------

    if (_containsAny(text, [
      'security',

      'auth',

      'token',

      'payment',

      'checkout',

      'session',

      'xss',

      'sql',

      'jwt',

      'permission',

      'access',
    ])) {
      return PriorityConstants.high;
    }

    // --------------------------------------------------------

    // MEDIUM

    // --------------------------------------------------------

    if (_containsAny(text, [
      'validation',

      'retry',

      'duplicate',

      'boundary',

      'field',

      'input',

      'format',
    ])) {
      return PriorityConstants.medium;
    }

    // --------------------------------------------------------

    // LOW

    // --------------------------------------------------------

    return PriorityConstants.low;
  }

  // ==========================================================

  // HELPERS

  // ==========================================================

  static bool _containsAny(String text, List<String> values) {
    for (final value in values) {
      if (text.contains(value)) {
        return true;
      }
    }

    return false;
  }
}

class PriorityConstants {
  const PriorityConstants._();

  static const high = 'High';

  static const medium = 'Medium';

  static const low = 'Low';

  static const all = [high, medium, low];
}
