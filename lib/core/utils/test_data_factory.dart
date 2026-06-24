import 'package:qa_genie/core/utils/stable_hash.dart';

// ============================================================
// FILE: lib/core/utils/test_data_factory.dart
// ============================================================

class TestDataFactory {
  const TestDataFactory._();

  // Allowed email domains (max 25 chars combined)
  static const _safeDomains = [
    'example.com',
    'test.com',
    'local.com',
    'sample.com',
    'qa.com',
  ];

  // Safe member name prefixes
  static const _safeMembers = ['member', 'tester', 'qa', 'admin', 'guest'];

  // ==========================================================
  // EMAILS (max 25 chars total)
  // ==========================================================
  static String validEmail([String seed = 'default']) {
    final name =
        _safeMembers[StableHash.forText('name-$seed', _safeMembers.length)];
    final domain =
        _safeDomains[StableHash.forText('domain-$seed', _safeDomains.length)];
    final result = '$name@$domain';
    // Ensure max length 25 (truncate if needed, but our data fits)
    return result.length <= 25 ? result : result.substring(0, 25);
  }

  static String emailUpper([String seed = 'default']) {
    return validEmail(seed).toUpperCase();
  }

  static String emailMixed([String seed = 'default']) {
    final e = validEmail(seed);
    return e
        .split('')
        .map(
          (c) =>
              StableHash.forText(c, 2) == 0 ? c.toUpperCase() : c.toLowerCase(),
        )
        .join();
  }

  static String emailMaxLength() => 'email_len_254'; // symbolic, not literal
  static String emailValidRegistered() => 'reg_email';
  static String emailDuplicateRegistered() => 'dup_email';
  static String emptyValue() => 'empty';
  static String spacesOnly() => 'spaces';
  static String invalidFormat() => 'invalid_fmt';

  // ==========================================================
  // PASSWORDS (max 25 chars)
  // ==========================================================
  static String validPassword([String seed = 'default']) {
    final idx = StableHash.forText('pwd-$seed', 900) + 100;
    return 'Pass@$idx'; // e.g., Pass@123 (<=12 chars)
  }

  static String passwordMinLength() => 'pwd_len_8';
  static String passwordMaxLength() => 'pwd_len_128';
  static String passwordExpired() => 'pwd_expired';
  static String invalidPassword() => 'bad_pwd';

  // ==========================================================
  // OTP / TOKENS (max 25 chars)
  // ==========================================================
  static String validOtp() => '123456';
  static String expiredOtp() => 'otp_expired';
  static String validToken() => 'token_valid';
  static String expiredToken() => 'token_expired';
  static String malformedJwt() => 'jwt_bad';

  // ==========================================================
  // OAUTH
  // ==========================================================
  static String providerGoogle() => 'google';
  static String providerGithub() => 'github';
  static String providerInvalid() => 'provider_invalid';
  static String oauthStateValid() => 'oauth_valid';
  static String oauthCallbackValid() => 'callback_valid';

  // ==========================================================
  // SESSION
  // ==========================================================
  static String sessionValid() => 'session_valid';
  static String sessionExpired() => 'session_expired';
  static String refreshTokenValid() => 'refresh_valid';
  static String refreshTokenExpired() => 'refresh_expired';
  static String deviceKnown() => 'device_known';
  static String deviceNew() => 'device_new';

  // ==========================================================
  // COMMERCE
  // ==========================================================
  static String itemValid() => 'item_001';
  static String itemOutOfStock() => 'item_oos';
  static String cartValid() => 'cart_active';
  static String couponValid() => 'save20';
  static String couponExpired() => 'coupon_expired';
  static String couponUsed() => 'coupon_used';
  static String giftCardValid() => 'giftcard_valid';
  static String quantityMin() => 'qty_1';
  static String quantityMax() => 'qty_max';
  static String addressValid() => 'addr_valid';

  // ==========================================================
  // CHECKOUT / PAYMENTS
  // ==========================================================
  static String cardValid() => 'card_valid';
  static String cardExpired() => 'card_expired';
  static String cardInvalid() => 'card_invalid';
  static String cvvValid() => '123';
  static String cvvInvalid() => 'cvv_bad';
  static String amountMin() => 'amt_1';
  static String amountMax() => 'amt_10000';
  static String paymentDuplicate() => 'payment_dup';

  // ==========================================================
  // BANKING
  // ==========================================================
  static String accountValid() => 'acct_valid';
  static String accountInvalid() => 'acct_invalid';
  static String beneficiaryValid() => 'benef_valid';
  static String beneficiaryDuplicate() => 'benef_duplicate';
  static String balanceSufficient() => 'balance_ok';
  static String balanceLow() => 'balance_low';
  static String transferMin() => 'amt_1';
  static String transferMax() => 'amt_10000';
  static String dailyLimit() => 'limit_daily';

  // ==========================================================
  // SCHEDULING
  // ==========================================================
  static String appointmentValid() => 'appt_valid';
  static String appointmentDuplicate() => 'appt_duplicate';
  static String providerValid() => 'provider_valid';
  static String providerUnavailable() => 'provider_busy';
  static String slotValid() => 'slot_valid';
  static String slotExpired() => 'slot_expired';
  static String insuranceValid() => 'ins_valid';
  static String insuranceInvalid() => 'ins_invalid';

  // ==========================================================
  // MEDICAL / PRESCRIPTION
  // ==========================================================
  static String patientValid() => 'patient_valid';
  static String prescriptionValid() => 'rx_valid';
  static String prescriptionInvalid() => 'rx_invalid';
  static String prescriptionExpired() => 'rx_expired';
  static String refillEarly() => 'refill_early';
  static String allergyFlag() => 'allergy_present';
  static String labResultValid() => 'lab_result';
  static String abnormalFlag() => 'abnormal_result';

  // ==========================================================
  // RECORDS
  // ==========================================================
  static String recordValid() => 'record_valid';
  static String recordLocked() => 'record_locked';
  static String consentValid() => 'consent_valid';
  static String consentMissing() => 'consent_missing';
  static String documentValid() => 'doc_valid';
  static String documentExpired() => 'doc_expired';

  // ==========================================================
  // TELEHEALTH
  // ==========================================================
  static String consultationValid() => 'consult_valid';
  static String providerNoShow() => 'provider_noshow';
  static String patientNoShow() => 'patient_noshow';
  static String networkFail() => 'network_fail';
  static String callbackValid() => 'callback_valid';
  static String webhookValid() => 'webhook_valid';
  static String retryValid() => 'retry_valid';
  static String timeoutCase() => 'timeout_case';

  // ==========================================================
  // INTEGRATION / API
  // ==========================================================
  static String endpointValid() => 'endpoint_valid';
  static String endpointInvalid() => 'endpoint_invalid';
  static String apiKeyValid() => 'apikey_valid';
  static String apiKeyExpired() => 'apikey_expired';
  static String payloadValid() => 'payload_valid';
  static String payloadInvalid() => 'payload_invalid';
  static String http200() => 'http_200';
  static String http401() => 'http_401';
  static String http429() => 'http_429';
  static String http500() => 'http_500';

  // ==========================================================
  // SECURITY (short symbolic payloads)
  // ==========================================================
  static String sqlInjection() => "'OR 1=1"; // max 7 chars
  static String xssPayload() => "<script>"; // 8 chars
  static String csrfMissing() => "csrf_missing";
  static String bruteForceCase() => "bruteforce";
  static String credentialStuffing() => "cred_stuffing";
  static String invalidToken() => "token_invalid";

  // ==========================================================
  // MISSING METHODS FOR DATA GENERATOR
  // ==========================================================
  static String validAmount() => 'amt_100';
  static String invalidAmount() => 'amt_invalid';
  static String beneficiary() => 'beneficiary';
  static String creditCardNumber() => 'card_valid';
  static String expiryDate() => '12/28';
  static String cvv() => '123';
  static String expiredCardNumber() => 'card_expired';
  static String validCoupon() => 'save20';
  static String invalidCoupon() => 'coupon_invalid';
  static String appointmentDate() => '2025-06-15';
  static String providerId() => 'provider_001';
  static String validPrescriptionId() => 'rx_valid';
  static String expiredPrescriptionId() => 'rx_expired';
  static String patientId() => 'patient_001';
  static String meetingLink() => 'meet.link/room';
  static String insurancePolicy() => 'ins_policy_123';

  // ==========================================================
  // GENERIC REALISTIC INPUT (switch removed, use explicit methods)
  // ==========================================================
  static String reference(String seed) {
    final value = StableHash.forText('ref-$seed', 9000) + 1000;
    return 'REF-$value'; // e.g., REF-1234 (max 11 chars)
  }

  // ==========================================================
  // SAFETY FILTER (unchanged, but all generated values already safe)
  // ==========================================================
  static bool isSafeInput(String value) {
    final text = value.trim();
    if (text.length > 25) return false; // hard limit
    if (RegExp(r'(.)\1{6,}').hasMatch(text)) return false;
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
      if (lower.contains(domain)) return false;
    }
    return true;
  }
}
