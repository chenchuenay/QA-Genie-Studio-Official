import 'dart:math';
import 'package:qa_genie/core/utils/stable_hash.dart';

/// Base class for domain‑specific test data generators.
abstract class DataGenerator {
  Map<String, dynamic> generate({
    required String outcome,
    required String seed,
  });
}

/// Authentication data generator using realistic, compact examples.
class AuthenticationDataGenerator implements DataGenerator {
  @override
  Map<String, dynamic> generate({
    required String outcome,
    required String seed,
  }) {
    final random = Random(StableHash.forText(seed, 999999));

    switch (outcome) {
      // ========== POSITIVE OUTCOMES ==========
      case 'valid_login':
        return {
          'email': _randomValidEmail(random),
          'password': _randomValidPassword(random),
        };
      case 'social_login':
        return {
          'provider': _randomSocialProvider(random),
          'email': _randomValidEmail(random),
        };
      case 'mfa_login':
        return {
          'email': _randomValidEmail(random),
          'password': _randomValidPassword(random),
          'otp': _randomValidOtp(random),
        };
      case 'remembered_session':
        return {
          'email': _randomValidEmail(random),
          'password': _randomValidPassword(random),
          'rememberMe': 'true',
        };

      // ========== NEGATIVE OUTCOMES ==========
      case 'invalid_password':
        return {
          'email': _randomValidEmail(random),
          'password': _randomInvalidPassword(random),
        };
      case 'locked_account':
        return {
          'email': _randomLockedAccount(random),
          'password': _randomValidPassword(random),
        };
      case 'nonexistent_user':
        return {
          'email': _randomNonexistentUser(random),
          'password': _randomValidPassword(random),
        };

      // ========== VALIDATION OUTCOMES ==========
      case 'empty_email':
        return {'email': '', 'password': _randomValidPassword(random)};
      case 'empty_password':
        return {'email': _randomValidEmail(random), 'password': ''};
      case 'invalid_email_format':
        return {
          'email': _randomInvalidEmail(random),
          'password': _randomValidPassword(random),
        };

      // ========== BOUNDARY OUTCOMES ==========
      case 'max_email_length':
        return {
          'email': _randomBoundaryEmail(random),
          'password': _randomValidPassword(random),
        };
      case 'max_password_length':
        return {
          'email': _randomValidEmail(random),
          'password': _randomBoundaryPassword(random),
        };

      // ========== SECURITY OUTCOMES ==========
      case 'sql_injection':
        return {
          'email': _randomSqlPayload(random),
          'password': _randomSqlPayload(random),
        };
      case 'xss':
        return {
          'email': _randomXssPayload(random),
          'password': _randomXssPayload(random),
        };

      // ========== SESSION OUTCOMES ==========
      case 'session_expiry':
        return {'token': _randomExpiredSession(random)};
      case 'concurrent_login':
        return {
          'session1': _randomActiveSession(random),
          'session2': _randomActiveSession(random),
        };

      default:
        return {'value': 'sample_${_randomSuffix(random)}'};
    }
  }

  // ---------- Email pools ----------
  String _randomValidEmail(Random random) {
    const emails = [
      'user@example.com',
      'jhon@example.org',
      'member_9@test.in',
      'admin@test.ai',
      'portal@example.ai',
    ];
    return emails[random.nextInt(emails.length)];
  }

  String _randomInvalidEmail(Random random) {
    const emails = [
      'invalid-email',
      'user@',
      '@example.com',
      'user..name@test.local',
      'user space@test.local',
    ];
    return emails[random.nextInt(emails.length)];
  }

  String _randomBoundaryEmail(Random random) {
    const emails = [
      'email_length_254@test.local',
      'email_length_200@test.local',
      'email_length_128@test.local',
    ];
    return emails[random.nextInt(emails.length)];
  }

  // ---------- Password pools ----------
  String _randomValidPassword(Random random) {
    const passwords = [
      'SecurePass@2',
      'Welcome#456',
      'StrongLogin!789',
      'AccessKey@321',
      'ValidUser#@9',
    ];
    return passwords[random.nextInt(passwords.length)];
  }

  String _randomInvalidPassword(Random random) {
    const passwords = [
      'wrong_password',
      'incorrect_password',
      'old_password',
      'reused_password',
      '1',
    ];
    return passwords[random.nextInt(passwords.length)];
  }

  String _randomBoundaryPassword(Random random) {
    const passwords = [
      'password_length_1',
      'password_length_128',
      'password_length_256',
    ];
    return passwords[random.nextInt(passwords.length)];
  }

  // ---------- OTP pools ----------
  String _randomValidOtp(Random random) {
    const otps = [
      'otp_generated_now',
      'otp_recently_generated',
      'otp_valid_2min',
    ];
    return otps[random.nextInt(otps.length)];
  }

  // ---------- Account status pools ----------
  String _randomLockedAccount(Random random) {
    const accounts = [
      'locked_account',
      'security_locked_account',
      'temporarily_locked_account',
    ];
    return accounts[random.nextInt(accounts.length)];
  }

  String _randomNonexistentUser(Random random) {
    const users = ['unknown_user', 'unregistered_user', 'nonexistent_account'];
    return users[random.nextInt(users.length)];
  }

  // ---------- Social login ----------
  String _randomSocialProvider(Random random) {
    const providers = [
      'Google',
      'Apple',
      'Microsoft',
      'GitHub',
      'LinkedIn',
      'Facebook',
    ];
    return providers[random.nextInt(providers.length)];
  }

  // ---------- Security payloads ----------
  String _randomSqlPayload(Random random) {
    const payloads = [
      'sql_injection_payload',
      'authentication_bypass_payload',
      'union_select_payload',
    ];
    return payloads[random.nextInt(payloads.length)];
  }

  String _randomXssPayload(Random random) {
    const payloads = [
      'xss_script_payload',
      'xss_event_payload',
      'xss_svg_payload',
    ];
    return payloads[random.nextInt(payloads.length)];
  }

  // ---------- Session tokens ----------
  String _randomExpiredSession(Random random) {
    const tokens = [
      'expired_session_token',
      'session_timeout_token',
      'inactive_session_token',
    ];
    return tokens[random.nextInt(tokens.length)];
  }

  String _randomActiveSession(Random random) {
    const tokens = [
      'active_session_token',
      'valid_session_token',
      'authenticated_session',
    ];
    return tokens[random.nextInt(tokens.length)];
  }

  // ---------- Helpers ----------
  int _randomSuffix(Random random) => random.nextInt(10000);
}
