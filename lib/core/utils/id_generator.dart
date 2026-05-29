// ============================================================
// lib/core/utils/id_generator.dart
// ============================================================

/// ============================================================
/// ID GENERATOR
/// ============================================================
///
/// Deterministic business ID generator.
///
/// PURPOSE:
/// - readable IDs
/// - export-safe IDs
/// - Jira-safe IDs
/// - stable suite indexing
///
/// OUTPUT EXAMPLE:
/// TC_LOGIN_001
///
class IdGenerator {
  const IdGenerator._();

  /// Generates deterministic readable ID.
  static String generate(String module, int index) {
    final mod = _normalize(module);

    final safeIndex = index.clamp(0, 9999).toString().padLeft(3, '0');

    return 'TC_${mod}_$safeIndex';
  }

  /// Generates forensic trace ID.
  ///
  /// Example:
  /// TRC_171726373_LOGIN
  static String trace(String context) {
    final normalized = _normalize(context);

    final ts = DateTime.now().millisecondsSinceEpoch;

    return 'TRC_${ts}_$normalized';
  }

  /// Generates export batch ID.
  ///
  /// Example:
  /// EXP_171726373
  static String exportBatch() {
    return 'EXP_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _normalize(String value) {
    final cleaned = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    if (cleaned.isEmpty) {
      return 'GENERIC';
    }

    final parts = cleaned.split('_');

    return parts.first.length > 18 ? parts.first.substring(0, 18) : parts.first;
  }
}
