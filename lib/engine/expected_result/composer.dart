import 'package:qa_genie/engine/business/business_area.dart';

class ExpectedResultComposer {
  static String compose({
    required String outcome,
    required BusinessArea businessArea,
    required List<String> observations,
    required String platform,
    required String feature,
  }) {
    // Remove duplicates and empty strings
    final uniqueObs = observations
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList();
    final outcomePhrase = _outcomeToPhrase(outcome);
    final businessEffect = _businessEffect(businessArea, outcome, feature);
    final allParts = <String>[outcomePhrase];
    allParts.addAll(uniqueObs);
    if (businessEffect.isNotEmpty) allParts.add(businessEffect);
    // Join with space, but avoid double spaces
    return allParts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _outcomeToPhrase(String outcome) {
    if (outcome.contains('invalid') ||
        outcome.contains('fail') ||
        outcome.contains('empty')) {
      return 'Authentication is rejected.';
    }
    if (outcome == 'social_login') {
      return 'OAuth login flow completes successfully.';
    }
    if (outcome == 'valid_login' || outcome == 'remembered_session') {
      return 'Authentication request is accepted.';
    }
    return 'Operation completes.';
  }

  static String _businessEffect(
    BusinessArea area,
    String outcome,
    String feature,
  ) {
    final isPositive =
        !outcome.contains('invalid') &&
        !outcome.contains('empty') &&
        !outcome.contains('expired') &&
        !outcome.contains('fail');
    if (area.id == 'authentication') {
      if (isPositive &&
          (outcome.contains('valid') ||
              outcome.contains('social') ||
              outcome.contains('mfa'))) {
        return 'User can access $feature features and protected resources.';
      } else {
        return 'User remains unable to access $feature.';
      }
    } else if (area.id == 'ecommerce') {
      if (isPositive && outcome == 'valid_checkout') {
        return 'Order is placed and confirmation is sent.';
      } else {
        return 'Order is not placed, cart remains unchanged.';
      }
    }
    return '';
  }
}
