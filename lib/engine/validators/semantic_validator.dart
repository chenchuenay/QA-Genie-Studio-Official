import 'package:qa_genie/core/utils/stable_hash.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';

// ============================================================
// lib/engine/validators/semantic_validator.dart
// ============================================================

class SemanticValidationResult {
  final List<WorkingCase> validCases;
  final Map<int, String> rejectedReasons;

  const SemanticValidationResult({
    required this.validCases,
    required this.rejectedReasons,
  });
}

class SemanticValidator {
  static final RegExp _alphaNumericPattern = RegExp(r'[^a-z0-9 ]');

  SemanticValidationResult validate(
    List<WorkingCase> cases,
    Function(RejectedCaseInfo) logRejected,
  ) {
    final valid = <WorkingCase>[];
    final rejected = <int, String>{};

    for (int index = 0; index < cases.length; index++) {
      final tc = cases[index];

      final profile = _extractSemanticProfile(tc);
      tc.metadata.semanticProfile = profile;

      final fingerprint = _buildFingerprint(tc, profile);
      tc.metadata.fingerprint = fingerprint;

      final reason = _validate(tc);

      if (reason == null) {
        valid.add(tc.copy());
      } else {
        rejected[index] = reason;
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: reason,
            stage: 'SemanticValidation',
          ),
        );
      }
    }

    return SemanticValidationResult(
      validCases: valid,
      rejectedReasons: rejected,
    );
  }

  String? _validate(WorkingCase tc) {
    if (tc.title.trim().length < 8) {
      return 'Hard Fail: Semantically weak title.';
    }
    if (_isGarbage(tc)) {
      return 'Hard Fail: Repetitive or meaningless semantic structure.';
    }
    if (_containsPlaceholder(tc.expectedResult)) {
      return 'Hard Fail: Placeholder expected result detected.';
    }
    return null;
  }

  // ✅ FIXED: Now uses TestStep.action correctly
  bool _isGarbage(WorkingCase tc) {
    if (tc.steps.length <= 1) return false;
    final normalizedActions = tc.steps
        .map((s) => _sanitizeText(s.action))
        .toList();
    final uniqueActions = normalizedActions.toSet();
    return uniqueActions.length < (normalizedActions.length / 2);
  }

  bool _containsPlaceholder(String text) {
    final lower = text.toLowerCase();
    const placeholders = [
      'lorem ipsum',
      'test test',
      'dummy',
      'sample response',
      'placeholder',
    ];
    return placeholders.any(lower.contains);
  }

  String _buildFingerprint(WorkingCase tc, String profile) {
    final actionChain = tc.steps.map((s) => _sanitizeText(s.action)).join('>');
    final failureMode =
        tc.expectedResult.toLowerCase().contains('error') ||
            tc.expectedResult.toLowerCase().contains('fail')
        ? 'neg'
        : 'pos';
    final hash = StableHash.forText(
      '$profile|$actionChain|$failureMode',
      1000000000,
    );
    return '$profile|$failureMode|$hash';
  }

  String _extractSemanticProfile(WorkingCase tc) {
    final text = '${tc.title} ${tc.expectedResult}'.toLowerCase();
    if (text.contains('login') || text.contains('auth')) return 'security';
    if (text.contains('payment') || text.contains('checkout'))
      return 'validation';
    if (text.contains('session') || text.contains('timeout')) return 'session';
    if (text.contains('accessibility') || text.contains('usability'))
      return 'usability';
    if (text.contains('offline') || text.contains('retry')) return 'resilience';
    return 'functional';
  }

  String _sanitizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll(_alphaNumericPattern, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
