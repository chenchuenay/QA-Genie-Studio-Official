import 'package:qa_genie/core/utils/stable_hash.dart';
// ============================================================
// FILE: lib/core/utils/test_data_factory.dart
// ============================================================

class TestDataFactory {
  const TestDataFactory._();

  // ==========================================================
  // SAFE USERS / DOMAINS
  // ==========================================================

  /// IMPORTANT:
  /// We allow:
  /// - realistic QA-style emails
  /// - user@example.com
  /// - mock/test/internal domains
  ///
  /// We DO NOT allow:
  /// - real company websites
  /// - real production emails
  /// - repeated garbage
  /// - huge payloads
  /// - accidental real identities

  static const _safeUsers = [
    'qa.user',
    'enterprise.tester',
    'release.operator',
    'security.auditor',
    'test.manager',
  ];

  static const _safeDomains = [
    'example.com',
    'example.test',
    'mock.internal',
    'qa.local',
  ];

  // ==========================================================
  // LONG TEST EMAILS
  // ==========================================================

  static const realisticLongEmails = [
    'enterprise.audit.user@example.test',
    'regional.operations.manager@mock.internal',
    'international.procurement.team@qa.local',
  ];

  // ==========================================================
  // LONG PASSWORDS
  // ==========================================================

  static const realisticLongPasswords = [
    'EnterprisePasswordExceedingAllowedLimit123!',
    'CorporateAdminCredentialBoundary456!',
    'SecurityCompliancePasswordPolicy789!',
  ];

  // ==========================================================
  // EMAILS
  // ==========================================================

  static String validEmail([String seed = 'default']) {
    final nameIdx = StableHash.forText('email-name-$seed', _safeUsers.length);

    final domainIdx = StableHash.forText(
      'email-domain-$seed',
      _safeDomains.length,
    );

    return '${_safeUsers[nameIdx]}@${_safeDomains[domainIdx]}';
  }

  static String invalidEmail([String seed = 'default']) {
    return 'invalid_email_format';
  }

  // ==========================================================
  // PASSWORDS
  // ==========================================================

  static String validPassword([String seed = 'default']) {
    final idx = StableHash.forText('password-$seed', 900) + 100;

    return 'QaPass@$idx';
  }

  static String invalidPassword([String seed = 'default']) {
    return '123';
  }

  // ==========================================================
  // TOKENS / OTP
  // ==========================================================

  /// SAFE MOCK TOKEN
  /// Looks realistic but is fake.
  static String validToken() {
    return 'mock.jwt.token.signature';
  }

  static String expiredToken() {
    return 'mock.jwt.expired.signature';
  }

  static String malformedJwt() {
    return 'header.payload.invalid';
  }

  static String validOtp() {
    return '827364';
  }

  static String expiredOtp() {
    return '000000';
  }

  // ==========================================================
  // SECURITY PAYLOADS
  // ==========================================================

  static String sqlInjection() {
    return "' UNION SELECT username,password FROM users --";
  }

  static String xssPayload() {
    return '<script>alert("xss")</script>';
  }

  // ==========================================================
  // ENTERPRISE SPECIFIC
  // ==========================================================

  static String inactivePayrollAccount() {
    return 'payroll_acct_inactive_99';
  }

  // ==========================================================
  // GENERIC REALISTIC INPUT
  // ==========================================================

  static String realisticInput(String label) {
    switch (label.toLowerCase()) {
      case 'email':
        return validEmail();

      case 'password':
        return validPassword();

      case 'otp':
        return validOtp();

      case 'token':
        return validToken();

      default:
        return 'qa_reference_001';
    }
  }

  // ==========================================================
  // REFERENCE
  // ==========================================================

  static String reference(String seed) {
    final value = StableHash.forText('reference-$seed', 9000) + 1000;

    return 'QA-REF-$value';
  }

  // ==========================================================
  // SAFETY FILTER
  // ==========================================================

  static bool isSafeInput(String value) {
    final text = value.trim();

    // --------------------------------------------------------
    // BLOCK EXTREME LENGTH
    // --------------------------------------------------------

    if (text.length > 120) {
      return false;
    }

    // --------------------------------------------------------
    // BLOCK REPEATED GARBAGE
    // Example:
    // aaaaaaaa@example.com
    // xxxxxxxxxxxxx
    // --------------------------------------------------------

    if (RegExp(r'(.)\1{6,}').hasMatch(text)) {
      return false;
    }

    // --------------------------------------------------------
    // BLOCK REAL DOMAINS
    // ALLOW:
    // example.com
    // *.test
    // *.local
    // *.internal
    // --------------------------------------------------------

    final lower = text.toLowerCase();

    const forbidden = [
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
      'outlook.com',
      'linkedin.com',
      'facebook.com',
      'amazon.com',
      'google.com',
    ];

    for (final domain in forbidden) {
      if (lower.contains(domain)) {
        return false;
      }
    }

    return true;
  }
}
