import 'package:qa_genie/engine/business/business_area.dart';

class TitleComposer {
  static String compose({
    required String outcome,
    required BusinessArea businessArea,
    required String feature,
    required String primaryObservation,
  }) {
    // First, try to get a specific title from a small, maintainable map
    final specificTitle = _specificTitle(outcome, businessArea, feature);
    if (specificTitle != null) return specificTitle;

    // Fallback: generate title from outcome tokens and feature
    return _fallbackTitle(outcome, feature);
  }

  static String? _specificTitle(
    String outcome,
    BusinessArea area,
    String feature,
  ) {
    // Authentication outcomes (most common)
    switch (outcome) {
      case 'valid_login':
        return 'Login with valid credentials';
      case 'social_login':
        return 'Login using social account';
      case 'mfa_login':
        return 'Multi‑factor authentication login';
      case 'remembered_session':
        return 'Remembered session restores login';
      case 'invalid_password':
        return 'Login fails with incorrect password';
      case 'locked_account':
        return 'Login attempt with locked account';
      case 'nonexistent_user':
        return 'Login with non‑existent user';
      case 'empty_email':
        return 'Login with empty email field';
      case 'empty_password':
        return 'Login with empty password field';
      case 'invalid_email_format':
        return 'Login with malformed email address';
      case 'max_email_length':
        return 'Email field handles maximum length';
      case 'max_password_length':
        return 'Password field handles maximum length';
      case 'sql_injection':
        return 'SQL injection attempt';
      case 'xss':
        return 'XSS payload in input';
      case 'session_expiry':
        return 'Session expiry redirects to login';
      case 'concurrent_login':
        return 'Concurrent login from another device';

      // E‑commerce
      case 'valid_checkout':
        return 'Complete checkout with valid payment';
      case 'expired_coupon':
        return 'Apply expired coupon code';
      case 'insufficient_stock':
        return 'Checkout with out‑of‑stock item';
      case 'invalid_payment':
        return 'Payment fails with invalid card';
      case 'price_tampering':
        return 'Price modification attempt';
      case 'quantity_overflow':
        return 'Add more than available quantity';

      // Banking
      case 'valid_transfer':
        return 'Money transfer to valid account';
      case 'add_beneficiary':
        return 'Add new beneficiary';
      case 'insufficient_funds':
        return 'Transfer fails due to insufficient balance';
      case 'invalid_otp':
        return 'Transfer with wrong OTP';
      case 'wrong_beneficiary':
        return 'Transfer to unverified beneficiary';

      default:
        return null;
    }
  }

  static String _fallbackTitle(String outcome, String feature) {
    // Remove 'generic_' prefix if present
    final clean = outcome.replaceFirst(RegExp(r'^generic_'), '');
    // Replace underscores with spaces
    final words = clean.replaceAll('_', ' ').trim();
    if (words.isEmpty) return 'Validate $feature functionality';
    // Capitalise first letter of each word
    final capitalized = words
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
    return '$capitalized test for $feature';
  }
}
