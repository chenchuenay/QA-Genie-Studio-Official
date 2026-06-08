import 'package:qa_genie/core/utils/stable_hash.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

class RealismValidator {
  static List<WorkingCase> validate(
    List<WorkingCase> cases,
    String constraints,
    void Function(RejectedCaseInfo) logRejected,
  ) {
    final valid = <WorkingCase>[];
    final usedTitles = <String>{};
    final semanticFingerprints = <String>{};

    for (final tc in cases) {
      final titleKey = tc.title.trim().toLowerCase();
      if (usedTitles.contains(titleKey)) {
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: 'Duplicate title within suite',
            stage: 'RealismValidation',
          ),
        );
        continue;
      }
      usedTitles.add(titleKey);

      final fingerprint = _buildSemanticFingerprint(tc);
      if (semanticFingerprints.contains(fingerprint)) {
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason:
                'Semantic duplicate (same intent, state, outcome, and test data)',
            stage: 'RealismValidation',
          ),
        );
        continue;
      }
      semanticFingerprints.add(fingerprint);

      if (_isGenericTitle(tc.title)) {
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: 'Generic title',
            stage: 'RealismValidation',
          ),
        );
        continue;
      }

      if (!_satisfiesConstraints(tc, constraints)) {
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: 'Category not allowed by constraint',
            stage: 'RealismValidation',
          ),
        );
        continue;
      }

      valid.add(tc);
    }
    return valid;
  }

  static String _buildSemanticFingerprint(WorkingCase tc) {
    final domain = _detectDomain(tc.module, tc.feature);
    final intent = _deriveIntent(tc);
    final preconditionsKey = _extractPreconditionsKey(tc.preconditions);
    // Include test data hash (distinguishes uppercase email, special chars, etc.)
    final testDataHash = StableHash.fingerprint(tc.testData).substring(0, 8);
    // Include expected result hash (distinguishes different success/error messages)
    final expectedHash = StableHash.fingerprint(
      tc.expectedResult,
    ).substring(0, 8);
    final outcomeType = _categorizeOutcome(tc.expectedResult);
    final category = tc.categoryLock;

    final raw =
        '$domain|$intent|$preconditionsKey|$testDataHash|$expectedHash|$outcomeType|$category';
    final fullHash = StableHash.fingerprint(raw);
    return fullHash.substring(0, fullHash.length.clamp(0, 16));
  }

  static String _detectDomain(String module, String feature) {
    final combined = '$module $feature'.toLowerCase();
    if (combined.contains('login') || combined.contains('auth'))
      return 'identity';
    if (combined.contains('checkout') || combined.contains('cart'))
      return 'commerce';
    if (combined.contains('transfer') || combined.contains('payment'))
      return 'transaction';
    if (combined.contains('appointment') || combined.contains('booking'))
      return 'scheduling';
    if (combined.contains('record') || combined.contains('lab'))
      return 'records';
    return 'general';
  }

  static String _deriveIntent(WorkingCase tc) {
    if (tc.intentId.isNotEmpty && tc.intentId != '__unknown__')
      return tc.intentId;
    final title = tc.title.toLowerCase();
    if (title.contains('login')) return 'login_active';
    if (title.contains('logout')) return 'logout';
    if (title.contains('reset')) return 'password_reset';
    return 'generic';
  }

  static String _extractPreconditionsKey(List<String> preconditions) {
    final text = preconditions.join(' ').toLowerCase();
    if (text.contains('active')) return 'active';
    if (text.contains('inactive')) return 'inactive';
    if (text.contains('locked')) return 'locked';
    if (text.contains('expired')) return 'expired';
    if (text.contains('admin')) return 'admin';
    if (text.contains('standard')) return 'standard';
    return 'default';
  }

  static String _categorizeOutcome(String expectedResult) {
    final lower = expectedResult.toLowerCase();
    if (lower.contains('redirect')) return 'redirect';
    if (lower.contains('error') || lower.contains('invalid')) return 'error';
    if (lower.contains('success')) return 'success';
    return 'other';
  }

  static bool _isGenericTitle(String title) {
    final low = title.toLowerCase();
    return low.contains('generic_positive') ||
        low.contains('generic_negative') ||
        low == 'positive test for apply promo code';
  }

  static bool _satisfiesConstraints(WorkingCase tc, String constraints) {
    final lower = constraints.toLowerCase();
    if (lower.contains('only security') && tc.categoryLock != 'security')
      return false;
    if (lower.contains('only validation') && tc.categoryLock != 'validation')
      return false;
    if (lower.contains('only boundary') && tc.categoryLock != 'boundary')
      return false;
    if (lower.contains('only positive') && tc.categoryLock != 'positive')
      return false;
    if (lower.contains('only negative') && tc.categoryLock != 'negative')
      return false;
    if (lower.contains('only session') && tc.categoryLock != 'session')
      return false;
    return true;
  }

  static bool isValid(FinalizedTestCase tc) {
    final lowTitle = tc.title.toLowerCase();
    if (lowTitle.contains('generic') ||
        lowTitle.contains('sample') ||
        lowTitle.length < 10)
      return false;
    if (tc.steps.isEmpty) return false;
    if (tc.expectedResult.isEmpty) return false;
    return true;
  }
}
