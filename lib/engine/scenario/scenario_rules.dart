import 'package:qa_genie/engine/business/business_area.dart';

/// Central deterministic rule engine for outcomes.
class ScenarioRules {
  // In _authenticationOutcomes, ensure positive list includes 'valid_login', 'social_login', 'mfa_login', 'remembered_session'
  // Negative: 'invalid_password', 'locked_account', 'nonexistent_user'
  // Validation: 'empty_email', 'empty_password', 'invalid_email_format'
  // etc. Already correct.
  /// Returns a list of possible outcome strings for a given business area and category.
  static List<String> getOutcomes(BusinessArea businessArea, String category) {
    switch (businessArea.id) {
      case 'authentication':
        return _authenticationOutcomes(category);
      case 'ecommerce':
        return _ecommerceOutcomes(category);
      case 'banking':
        return _bankingOutcomes(category);
      default:
        return _defaultOutcomes(category);
    }
  }

  static List<String> _authenticationOutcomes(String category) {
    switch (category) {
      case 'positive':
        return [
          'valid_login',
          'social_login',
          'mfa_login',
          'remembered_session',
        ];
      case 'negative':
        return ['invalid_password', 'locked_account', 'nonexistent_user'];
      case 'validation':
        return ['empty_email', 'empty_password', 'invalid_email_format'];
      case 'boundary':
        return ['max_email_length', 'max_password_length'];
      case 'security':
        return ['sql_injection', 'xss'];
      case 'session':
        return ['session_expiry', 'concurrent_login'];
      default:
        return ['generic_${category}'];
    }
  }

  static List<String> _ecommerceOutcomes(String category) {
    switch (category) {
      case 'positive':
        return ['valid_checkout', 'coupon_apply', 'gift_card'];
      case 'negative':
        return ['expired_coupon', 'insufficient_stock', 'invalid_payment'];
      case 'security':
        return ['price_tampering', 'quantity_overflow'];
      default:
        return ['ecom_${category}_generic'];
    }
  }

  static List<String> _bankingOutcomes(String category) {
    switch (category) {
      case 'positive':
        return ['valid_transfer', 'add_beneficiary'];
      case 'negative':
        return ['insufficient_funds', 'invalid_otp', 'wrong_beneficiary'];
      default:
        return ['bank_${category}_generic'];
    }
  }

  static List<String> _defaultOutcomes(String category) {
    return ['generic_${category}'];
  }

  /// Returns a human‑readable description of an outcome (used for title fallback).
  static String describeOutcome(String outcome) {
    switch (outcome) {
      case 'valid_login':
        return 'valid credentials';
      case 'social_login':
        return 'social login';
      case 'mfa_login':
        return 'multi‑factor authentication';
      case 'remembered_session':
        return 'remembered session';
      case 'invalid_password':
        return 'invalid password';
      case 'locked_account':
        return 'locked account';
      case 'nonexistent_user':
        return 'nonexistent user';
      case 'empty_email':
        return 'empty email';
      case 'empty_password':
        return 'empty password';
      case 'invalid_email_format':
        return 'invalid email format';
      case 'max_email_length':
        return 'maximum email length';
      case 'max_password_length':
        return 'maximum password length';
      case 'sql_injection':
        return 'SQL injection';
      case 'xss':
        return 'XSS attack';
      case 'session_expiry':
        return 'session expiry';
      case 'concurrent_login':
        return 'concurrent login';
      case 'valid_checkout':
        return 'valid checkout';
      case 'expired_coupon':
        return 'expired coupon';
      case 'price_tampering':
        return 'price tampering';
      case 'valid_transfer':
        return 'money transfer';
      case 'invalid_otp':
        return 'invalid OTP';
      case 'insufficient_funds':
        return 'insufficient funds';
      default:
        return outcome.replaceAll('_', ' ');
    }
  }
}
