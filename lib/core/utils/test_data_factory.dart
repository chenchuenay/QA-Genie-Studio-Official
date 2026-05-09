import 'package:qa_app/core/utils/stable_hash.dart';

class TestDataFactory {
  static const _names = ['locked', 'pending', 'active', 'review', 'audit'];

  // Emails
  static String validEmail([String seed = 'default']) {
    final idx = StableHash.forText('email-$seed', _names.length);
    return 'qa_user_${_names[idx]}@domain.test';
  }

  static String invalidEmail([String seed = 'default']) {
    final idx = StableHash.forText('invalid-email-$seed', _names.length);
    return 'invalid_${_names[idx]}_email';
  }

  // Passwords
  static String validPassword([String seed = 'default']) {
    final idx = StableHash.forText('password-$seed', 900) + 100;
    return 'S3curePass!$idx';
  }

  static String invalidPassword([String seed = 'default']) {
    final idx = StableHash.forText('weak-password-$seed', 90) + 10;
    return 'short$idx';
  }

  // Phones
  static String validPhone() => '+971500000001';
  static String invalidPhone() => '+97150';

  // OTPs
  static String validOtp() => '654321';
  static String expiredOtp() => '111111';

  // Security payloads
  static String sqlInjection() => "' OR '1'='1";
  static String xssPayload() => '<script>alert(1)</script>';

  // Tokens
  static String validToken() => 'session_token_alpha_001';
  static String expiredToken() => 'expired_session_token';

  // Generic realistic
  static String realisticInput(String label) {
    switch (label) {
      case 'email':
        return validEmail();
      case 'password':
        return validPassword();
      case 'phone':
        return validPhone();
      case 'otp':
        return validOtp();
      default:
        return 'qa_reference_001';
    }
  }

  static String reference(String seed) {
    final value = StableHash.forText('reference-$seed', 9000) + 1000;
    return 'QA-REF-$value';
  }
}
