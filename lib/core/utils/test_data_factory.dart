import 'package:qa_genie/core/utils/stable_hash.dart';

class TestDataFactory {
  static const _corpUsers = ['corporate.user', 'payroll.admin', 'security.auditor', 'suspended.account', 'inactive.payroll'];
  static const _corpDomains = ['acmefinance.com', 'acmepayroll.org', 'fintech.test'];

  static const realisticLongEmails = [
    'enterprise.audit.user@acmefinance.com',
    'regional.operations.manager@acmepayroll.org',
    'international.procurement.team@fintech.test',
  ];
  
  static const realisticLongPasswords = [
    'EnterprisePasswordExceedingAllowedLimit123!',
    'CorporateAdminCredentialBeyondBoundary456!',
    'SecurityComplianceStrictPasswordPolicy789!',
  ];

  // Emails
  static String validEmail([String seed = 'default']) {
    final nameIdx = StableHash.forText('email-name-$seed', _corpUsers.length);
    final domainIdx = StableHash.forText('email-domain-$seed', _corpDomains.length);
    return '${_corpUsers[nameIdx]}@${_corpDomains[domainIdx]}';
  }

  static String invalidEmail([String seed = 'default']) {
    return 'invalid_format_email@domain';
  }

  // Passwords
  static String validPassword([String seed = 'default']) {
    final idx = StableHash.forText('password-$seed', 900) + 100;
    return 'Ent3rprisePass!$idx';
  }

  static String invalidPassword([String seed = 'default']) {
    return 'short123';
  }

  // Tokens/OTP
  static String validToken() => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ';
  static String expiredToken() => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxMDAwMDAwMDAwfQ';
  static String validOtp() => '827364';
  static String expiredOtp() => '000000';

  // Security payloads
  static String sqlInjection() => "' UNION SELECT null, username, password FROM users --";
  static String xssPayload() => '"><script>alert("QA-Enterprise-XSS")</script>';

  // Enterprise specific
  static String inactivePayrollAccount() => 'payroll_acct_inactive_99';
  static String malformedJwt() => 'header.payload.signature_invalid';

  // Generic realistic
  static String realisticInput(String label) {
    switch (label) {
      case 'email':
        return validEmail();
      case 'password':
        return validPassword();
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
