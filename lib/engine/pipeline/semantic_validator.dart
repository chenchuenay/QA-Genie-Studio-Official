import 'package:qa_genie/core/utils/stable_hash.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/pipeline/generation_context.dart';

class SemanticValidationResult {
  final List<WorkingCase> validCases;
  final Map<int, String> rejectedReasons;

  SemanticValidationResult({
    required this.validCases,
    required this.rejectedReasons,
  });
}

class SemanticValidator {
  static final RegExp _alphaNumericPattern = RegExp(r'[^a-z0-9 ]');

  SemanticValidationResult validate(
    GenerationContext context,
    List<WorkingCase> cases,
  ) {
    final valid = <WorkingCase>[];
    final rejected = <int, String>{};

    for (var index = 0; index < cases.length; index++) {
      final tc = cases[index];

      // Compute fingerprint and profile once
      final profile = _extractSemanticProfile(tc);
      tc.metadata.semanticProfile = profile;

      final fingerprint = _buildFingerprint(tc, profile);
      tc.metadata.fingerprint = fingerprint;

      final reason = _validate(tc);
      if (reason == null) {
        valid.add(tc.copy());
      } else {
        rejected[index] = reason;
        context.logRejected(
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

  String _sanitizeText(String input) {
    return input.toLowerCase().replaceAll(_alphaNumericPattern, ' ').trim();
  }

  String _buildFingerprint(WorkingCase tc, String profile) {
    final actionChain = tc.steps.map((s) => _sanitizeText(s.action)).join('>');
    final failureMode =
        (tc.expectedResult.toLowerCase().contains('error') ||
            tc.expectedResult.toLowerCase().contains('fail'))
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

  String? _validate(WorkingCase tc) {
    // Hard-fail semantic rules
    if (tc.title.trim().length < 8) {
      return 'Hard Fail: Title is semantically empty or too short.';
    }

    // Check for repetitive phrases (Garbage check)
    if (_isGarbage(tc)) {
      return 'Hard Fail: Semantic garbage detected (repetitive step content).';
    }

    return null;
  }

  bool _isGarbage(WorkingCase tc) {
    if (tc.steps.length > 5) {
      final actions = tc.steps.map((s) => _sanitizeText(s.action)).toSet();
      if (actions.length < tc.steps.length / 2) return true;
    }
    return false;
  }
}
