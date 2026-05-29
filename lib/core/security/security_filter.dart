import 'package:qa_genie/core/security/pii_scrubber.dart';
import 'package:qa_genie/core/config/app_environment.dart';
// ============================================================
// FILE: lib/core/security/security_filter.dart
// ============================================================


/// ===============================================================
///
/// SECURITY FILTER
///
/// PURPOSE:
/// - Centralized prompt sanitization
/// - Prompt injection mitigation
/// - Payload normalization
/// - Unsafe content stripping
/// - AI boundary hardening
///
/// IMPORTANT:
/// THIS RUNS BEFORE EVERY AI REQUEST.
///
/// FLOW:
///
/// User Input
///    ↓
/// SecurityFilter
///    ↓
/// PIIScrubber
///    ↓
/// PromptComposer
///    ↓
/// AI Provider
///
/// ===============================================================
class SecurityFilter {
  const SecurityFilter._();

  // ============================================================
  // HARD BLOCK PHRASES
  // ============================================================

  static const List<String> _blockedPhrases = [
    // PROMPT OVERRIDE
    'ignore previous instructions',
    'ignore all instructions',
    'disregard system prompt',
    'forget previous instructions',
    'override instructions',

    // SYSTEM EXTRACTION
    'reveal system prompt',
    'show hidden prompt',
    'display internal prompt',
    'show developer message',

    // EXECUTION
    'execute shell',
    'run command',
    'execute script',
    'run powershell',
    'run terminal',

    // FILE ACCESS
    'read local file',
    'access filesystem',
    'read secrets',
    'dump credentials',

    // ABUSE
    'generate infinite',
    'repeat forever',
    'spam generation',
    'flood output',

    // TOKEN ATTACKS
    'api key',
    'secret token',
    'private credential',
  ];

  // ============================================================
  // UNSAFE SYMBOLS
  // ============================================================

  static final RegExp _unsafeChars = RegExp(
    r'[`]{3,}|<script|</script>|<iframe|</iframe>',
    caseSensitive: false,
  );

  // ============================================================
  // EXTREME REPETITION
  // ============================================================

  static final RegExp _repetitionPattern = RegExp(r'(.)\1{20,}');

  // ============================================================
  // CONTROL CHARS
  // ============================================================

  static final RegExp _controlChars = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]');

  // ============================================================
  // MAIN FILTER
  // ============================================================

  static SecurityFilterResult sanitize(String input) {
    final findings = <String>[];

    if (input.trim().isEmpty) {
      return const SecurityFilterResult(
        sanitized: '',
        blocked: false,
        findings: [],
      );
    }

    String sanitized = input;

    // ==========================================================
    // NORMALIZE
    // ==========================================================

    sanitized = sanitized
        .replaceAll(_controlChars, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final lower = sanitized.toLowerCase();

    // ==========================================================
    // BLOCK PHRASES
    // ==========================================================

    for (final phrase in _blockedPhrases) {
      if (lower.contains(phrase)) {
        findings.add('blocked_phrase:$phrase');

        sanitized = sanitized.replaceAll(
          RegExp(phrase, caseSensitive: false),
          '[BLOCKED]',
        );
      }
    }

    // ==========================================================
    // SCRIPT STRIPPING
    // ==========================================================

    if (_unsafeChars.hasMatch(sanitized)) {
      findings.add('unsafe_markup_detected');

      sanitized = sanitized.replaceAll(_unsafeChars, '[REMOVED]');
    }

    // ==========================================================
    // REPETITION ATTACKS
    // ==========================================================

    if (_repetitionPattern.hasMatch(sanitized)) {
      findings.add('repetition_attack_detected');

      sanitized = sanitized.replaceAll(_repetitionPattern, '[TRUNCATED]');
    }

    // ==========================================================
    // PII SCRUBBING
    // ==========================================================

    if (EnvironmentAuthority.requirePiiScrubbing) {
      final piiFindings = PIIScrubber.detect(sanitized);

      findings.addAll(piiFindings.map((e) => 'pii:$e'));

      sanitized = PIIScrubber.scrub(sanitized);
    }

    // ==========================================================
    // LENGTH LIMIT
    // ==========================================================

    if (sanitized.length > EnvironmentAuthority.maxPromptCharacters) {
      findings.add('payload_truncated');

      sanitized = sanitized.substring(
        0,
        EnvironmentAuthority.maxPromptCharacters,
      );
    }

    // ==========================================================
    // FINAL CLEAN
    // ==========================================================

    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();

    // ==========================================================
    // HARD BLOCK DECISION
    // ==========================================================

    final blocked = findings.any(
      (e) => e.contains('blocked_phrase') || e.contains('unsafe_markup'),
    );

    return SecurityFilterResult(
      sanitized: sanitized,
      blocked: blocked,
      findings: findings,
    );
  }

  // ============================================================
  // SAFE CHECK
  // ============================================================

  static bool isSafe(String input) {
    final result = sanitize(input);
    return !result.blocked;
  }
}

/// ===============================================================
///
/// FILTER RESULT
///
/// ===============================================================
class SecurityFilterResult {
  final String sanitized;

  final bool blocked;

  final List<String> findings;

  const SecurityFilterResult({
    required this.sanitized,
    required this.blocked,
    required this.findings,
  });

  bool get hasFindings => findings.isNotEmpty;
}
