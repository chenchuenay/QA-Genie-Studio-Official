import 'dart:convert';
import 'package:crypto/crypto.dart';
// lib/core/utils/stable_hash.dart

/// ============================================================
/// STABLE HASH
/// ============================================================
///
/// Deterministic hashing utility.
///
/// PURPOSE:
/// - deterministic category selection
/// - stable planner branching
/// - export-safe repeatability
/// - fallback distribution
/// - diversity balancing
///
/// IMPORTANT:
/// - never use Random()
/// - never use runtime hashCode
/// - output must remain stable across app restarts
///
class StableHash {
  const StableHash._();

  /// Returns deterministic integer index from text.
  ///
  /// Example:
  /// StableHash.forText("login flow", 5)
  ///
  /// Always returns:
  /// 0 <= result < max
  static int forText(String text, int max) {
    if (max <= 1) {
      return 0;
    }

    final normalized = _normalize(text);

    if (normalized.isEmpty) {
      return 0;
    }

    final bytes = utf8.encode(normalized);

    final digest = sha1.convert(bytes).bytes;

    int hash = 0;

    for (int i = 0; i < 4; i++) {
      hash = (hash << 8) | digest[i];
    }

    return hash.abs() % max;
  }

  /// Creates deterministic hexadecimal fingerprint.
  ///
  /// Used for:
  /// - duplicate detection
  /// - semantic clustering
  /// - forensic comparison
  /// - export integrity
  static String fingerprint(String text) {
    final normalized = _normalize(text);

    if (normalized.isEmpty) {
      return 'EMPTY_HASH';
    }

    return sha1.convert(utf8.encode(normalized)).toString();
  }

  /// Combines multiple fields into one stable hash.
  static String compositeFingerprint({
    required String title,
    required String module,
    required String feature,
    required String expectedResult,
  }) {
    final buffer = StringBuffer()
      ..write(_normalize(title))
      ..write('|')
      ..write(_normalize(module))
      ..write('|')
      ..write(_normalize(feature))
      ..write('|')
      ..write(_normalize(expectedResult));

    return fingerprint(buffer.toString());
  }

  static String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
