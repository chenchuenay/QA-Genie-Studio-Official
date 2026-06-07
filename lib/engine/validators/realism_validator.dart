import 'package:qa_genie/engine/models/pipeline_models.dart';

class RealismValidator {
  static List<WorkingCase> validate(
    List<WorkingCase> cases,
    String constraints,
    void Function(RejectedCaseInfo) logRejected,
  ) {
    final valid = <WorkingCase>[];
    final usedTitles = <String>{};
    final usedFingerprints = <String>{};

    for (final tc in cases) {
      // Duplicate title
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

      // Duplicate step flow (fingerprint)
      final fingerprint = tc.steps.map((s) => s.action).join('|');
      if (usedFingerprints.contains(fingerprint)) {
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: 'Duplicate step flow',
            stage: 'RealismValidation',
          ),
        );
        continue;
      }
      usedFingerprints.add(fingerprint);

      // Generic title
      final lowTitle = tc.title.toLowerCase();
      if (lowTitle.contains('generic_positive') ||
          lowTitle.contains('generic_negative') ||
          lowTitle.contains('generic_validation') ||
          lowTitle.contains('generic_boundary') ||
          lowTitle == 'positive test for apply promo code' ||
          lowTitle == 'negative test for apply promo code') {
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: 'Generic title',
            stage: 'RealismValidation',
          ),
        );
        continue;
      }

      // Category leakage against constraints
      final lowerConstraints = constraints.toLowerCase();
      if (lowerConstraints.contains('only security') &&
          tc.categoryLock != 'security') {
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: 'Category not allowed by constraint (security only)',
            stage: 'RealismValidation',
          ),
        );
        continue;
      }
      if (lowerConstraints.contains('only validation') &&
          tc.categoryLock != 'validation') {
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: 'Category not allowed by constraint (validation only)',
            stage: 'RealismValidation',
          ),
        );
        continue;
      }
      if (lowerConstraints.contains('only boundary') &&
          tc.categoryLock != 'boundary') {
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: 'Category not allowed by constraint (boundary only)',
            stage: 'RealismValidation',
          ),
        );
        continue;
      }
      if (lowerConstraints.contains('only positive') &&
          tc.categoryLock != 'positive') {
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: 'Category not allowed by constraint (positive only)',
            stage: 'RealismValidation',
          ),
        );
        continue;
      }
      if (lowerConstraints.contains('only negative') &&
          tc.categoryLock != 'negative') {
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: 'Category not allowed by constraint (negative only)',
            stage: 'RealismValidation',
          ),
        );
        continue;
      }
      if (lowerConstraints.contains('only session') &&
          tc.categoryLock != 'session') {
        logRejected(
          RejectedCaseInfo(
            title: tc.title,
            reason: 'Category not allowed by constraint (session only)',
            stage: 'RealismValidation',
          ),
        );
        continue;
      }

      valid.add(tc);
    }
    return valid;
  }
}
