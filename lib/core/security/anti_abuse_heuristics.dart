import 'dart:math';
// ============================================================
// FILE: lib/core/security/anti_abuse_heuristics.dart
// ============================================================

/// ===============================================================
///
/// ANTI ABUSE HEURISTICS
///
/// PURPOSE:
/// - Lightweight deterministic abuse prevention
/// - Prevent spam generation loops
/// - Detect automation patterns
/// - Protect AI token budget
/// - Reduce accidental infinite usage
///
/// IMPORTANT:
/// THIS IS NOT PRIMARY SECURITY.
///
/// PRIMARY SECURITY:
/// - Firebase App Check
/// - Server quotas
/// - Signed generation tokens
///
/// THIS IS:
/// CLIENT-SIDE HEURISTIC RESISTANCE.
///
/// ===============================================================
class AntiAbuseHeuristics {
  AntiAbuseHeuristics._();

  // ============================================================
  // MEMORY STATE
  // ============================================================

  static final List<DateTime> _generationHistory = [];

  static final List<String> _recentFingerprints = [];

  static DateTime? _lastRequestTime;

  // ============================================================
  // CONFIG
  // ============================================================

  static const int _maxRequestsPerMinute = 10;

  static const int _maxDuplicateFingerprints = 3;

  static const int _minimumSecondsBetweenRequests = 2;

  static const int _fingerprintMemorySize = 20;

  // ============================================================
  // MAIN VALIDATION
  // ============================================================

  static AbuseCheckResult validate({
    required String module,
    required String feature,
    required String platform,
    required int count,
  }) {
    final findings = <String>[];

    final now = DateTime.now();

    // ==========================================================
    // CLEAN OLD HISTORY
    // ==========================================================

    _generationHistory.removeWhere((t) => now.difference(t).inMinutes >= 1);

    // ==========================================================
    // RATE LIMIT
    // ==========================================================

    if (_generationHistory.length >= _maxRequestsPerMinute) {
      findings.add('rate_limit_exceeded');
    }

    // ==========================================================
    // RAPID FIRE DETECTION
    // ==========================================================

    if (_lastRequestTime != null) {
      final diff = now.difference(_lastRequestTime!).inSeconds;

      if (diff < _minimumSecondsBetweenRequests) {
        findings.add('rapid_fire_detected');
      }
    }

    _lastRequestTime = now;

    // ==========================================================
    // DUPLICATE SPAM
    // ==========================================================

    final fingerprint = _buildFingerprint(
      module: module,
      feature: feature,
      platform: platform,
      count: count,
    );

    final duplicates = _recentFingerprints
        .where((e) => e == fingerprint)
        .length;

    if (duplicates >= _maxDuplicateFingerprints) {
      findings.add('duplicate_generation_pattern');
    }

    // ==========================================================
    // INVALID INPUT
    // ==========================================================

    if (_looksAutomated(module) || _looksAutomated(feature)) {
      findings.add('automated_input_pattern');
    }

    // ==========================================================
    // EXCESSIVE COUNTS
    // ==========================================================

    if (count > 30) {
      findings.add('excessive_generation_count');
    }

    // ==========================================================
    // RECORD
    // ==========================================================

    _generationHistory.add(now);

    _recentFingerprints.add(fingerprint);

    if (_recentFingerprints.length > _fingerprintMemorySize) {
      _recentFingerprints.removeAt(0);
    }

    // ==========================================================
    // FINAL DECISION
    // ==========================================================

    final blocked =
        findings.contains('rate_limit_exceeded') ||
        findings.contains('duplicate_generation_pattern');

    return AbuseCheckResult(
      blocked: blocked,
      findings: findings,
      riskScore: _calculateRiskScore(findings),
    );
  }

  // ============================================================
  // FINGERPRINT
  // ============================================================

  static String _buildFingerprint({
    required String module,
    required String feature,
    required String platform,
    required int count,
  }) {
    return [
      module.trim().toLowerCase(),
      feature.trim().toLowerCase(),
      platform.trim().toLowerCase(),
      count,
    ].join('|');
  }

  // ============================================================
  // AUTOMATION DETECTION
  // ============================================================

  static bool _looksAutomated(String input) {
    final lower = input.toLowerCase();

    // ==========================================================
    // EXTREME LENGTH
    // ==========================================================

    if (input.length > 500) {
      return true;
    }

    // ==========================================================
    // REPETITION
    // ==========================================================

    if (RegExp(r'(.)\1{10,}').hasMatch(input)) {
      return true;
    }

    // ==========================================================
    // SCRIPTING
    // ==========================================================

    const suspicious = [
      '<script',
      'while(true)',
      'for(',
      'eval(',
      'exec(',
      'drop table',
      'select *',
      'union select',
      'curl ',
      'wget ',
      'powershell',
      'cmd.exe',
    ];

    for (final pattern in suspicious) {
      if (lower.contains(pattern)) {
        return true;
      }
    }

    // ==========================================================
    // EXCESSIVE SYMBOLS
    // ==========================================================

    final symbolCount = RegExp(r'[^a-zA-Z0-9 ]').allMatches(input).length;

    final ratio = symbolCount / max(input.length, 1);

    if (ratio > 0.35) {
      return true;
    }

    return false;
  }

  // ============================================================
  // RISK SCORE
  // ============================================================

  static double _calculateRiskScore(List<String> findings) {
    double score = 0;

    for (final finding in findings) {
      switch (finding) {
        case 'rate_limit_exceeded':
          score += 0.5;
          break;

        case 'duplicate_generation_pattern':
          score += 0.3;
          break;

        case 'rapid_fire_detected':
          score += 0.15;
          break;

        case 'automated_input_pattern':
          score += 0.4;
          break;

        case 'excessive_generation_count':
          score += 0.2;
          break;

        default:
          score += 0.05;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  // ============================================================
  // RESET
  // ============================================================

  static void reset() {
    _generationHistory.clear();
    _recentFingerprints.clear();
    _lastRequestTime = null;
  }
}

/// ===============================================================
///
/// RESULT
///
/// ===============================================================
class AbuseCheckResult {
  final bool blocked;

  final List<String> findings;

  final double riskScore;

  const AbuseCheckResult({
    required this.blocked,
    required this.findings,
    required this.riskScore,
  });

  bool get isHighRisk => riskScore >= 0.7;

  bool get hasWarnings => findings.isNotEmpty;
}
