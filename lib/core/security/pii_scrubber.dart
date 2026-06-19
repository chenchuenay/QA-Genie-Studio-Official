// ============================================================
// FILE: lib/core/security/pii_scrubber.dart
// ============================================================

/// ===============================================================
///
/// PII SCRUBBER
///
/// PURPOSE:
/// - Prevent accidental leakage of sensitive information
/// - Reduce prompt injection attack surface
/// - Avoid real user/company data exposure
/// - Sanitize prompts BEFORE AI transmission
///
/// IMPORTANT:
/// THIS IS NOT A FULL DLP ENGINE.
/// THIS IS A LIGHTWEIGHT DETERMINISTIC SANITIZER.
///
/// MUST RUN:
/// BEFORE PromptComposer output reaches API layer.
///
/// ===============================================================
class PIIScrubber {
  const PIIScrubber._();

  // ============================================================
  // EMAILS
  // ============================================================

  static final RegExp _emailRegex = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );

  // ============================================================
  // PHONE NUMBERS
  // ============================================================

  static final RegExp _phoneRegex = RegExp(r'(\+?\d[\d\-\s]{7,}\d)');

  // ============================================================
  // URLS
  // ============================================================

  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+)|(www\.[^\s]+)',
    caseSensitive: false,
  );

  // ============================================================
  // IPV4
  // ============================================================

  static final RegExp _ipRegex = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b');

  // ============================================================
  // JWT TOKENS
  // ============================================================

  static final RegExp _jwtRegex = RegExp(
    r'eyJ[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+',
  );

  // ============================================================
  // UUID
  // ============================================================

  static final RegExp _uuidRegex = RegExp(
    r'\b[0-9a-f]{8}-'
    r'[0-9a-f]{4}-'
    r'[1-5][0-9a-f]{3}-'
    r'[89ab][0-9a-f]{3}-'
    r'[0-9a-f]{12}\b',
    caseSensitive: false,
  );

  // ============================================================
  // ACCESS KEYS
  // ============================================================

  static final RegExp _apiKeyRegex = RegExp(
    r'(sk_live_|sk_test_|AIza|ghp_)[A-Za-z0-9\-_]+',
    caseSensitive: false,
  );

  // ============================================================
  // CREDIT CARD
  // ============================================================

  static final RegExp _cardRegex = RegExp(r'\b(?:\d[ -]*?){13,16}\b');

  static bool _luhnCheck(String digits) {
    if (digits.length < 13 || digits.length > 16) return false;
    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = digits.codeUnitAt(i) - 48;
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  static String _replaceCards(String input) {
    return input.replaceAllMapped(_cardRegex, (match) {
      final raw = match.group(0)!;
      final digits = raw.replaceAll(RegExp(r'[ -]'), '');
      if (digits.length < 13 || digits.length > 16) return raw;
      if (!_luhnCheck(digits)) return raw;
      return '[REDACTED_CARD]';
    });
  }

  // ============================================================
  // LONG RANDOM TOKENS
  // ============================================================

  static final RegExp _longTokenRegex = RegExp(r'\b[a-zA-Z0-9\-_]{40,}\b');

  // ============================================================
  // MAIN SCRUB
  // ============================================================

  static String scrub(String input) {
    if (input.trim().isEmpty) {
      return input;
    }

    String sanitized = input;

    // ==========================================================
    // ORDER MATTERS
    // Most-specific → least-specific to avoid regex cross-match.
    // UUID, cards, API keys, JWTs, URLs, IPs before phone/email
    // because phone regex matches digit-dash patterns in UUIDs/cards.
    // ==========================================================

    sanitized = sanitized.replaceAll(_uuidRegex, '[REDACTED_UUID]');

    sanitized = _replaceCards(sanitized);

    sanitized = sanitized.replaceAll(_apiKeyRegex, '[REDACTED_API_KEY]');

    sanitized = sanitized.replaceAll(_jwtRegex, '[REDACTED_JWT]');

    sanitized = sanitized.replaceAll(_emailRegex, '[REDACTED_EMAIL]');

    sanitized = sanitized.replaceAll(_urlRegex, '[REDACTED_URL]');

    sanitized = sanitized.replaceAll(_ipRegex, '[REDACTED_IP]');

    sanitized = sanitized.replaceAll(_phoneRegex, '[REDACTED_PHONE]');

    sanitized = sanitized.replaceAll(_longTokenRegex, '[REDACTED_TOKEN]');

    // ==========================================================
    // WHITESPACE NORMALIZATION
    // ==========================================================

    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return sanitized;
  }

  // ============================================================
  // DETECTION ONLY
  // ============================================================

  static bool containsSensitiveData(String input) {
    return _emailRegex.hasMatch(input) ||
        _phoneRegex.hasMatch(input) ||
        _urlRegex.hasMatch(input) ||
        _ipRegex.hasMatch(input) ||
        _jwtRegex.hasMatch(input) ||
        _uuidRegex.hasMatch(input) ||
        _apiKeyRegex.hasMatch(input) ||
        _cardRegex.hasMatch(input) ||
        _longTokenRegex.hasMatch(input);
  }

  // ============================================================
  // DIAGNOSTICS
  // ============================================================

  static List<String> detect(String input) {
    final findings = <String>[];

    if (_emailRegex.hasMatch(input)) {
      findings.add('email');
    }

    if (_phoneRegex.hasMatch(input)) {
      findings.add('phone');
    }

    if (_urlRegex.hasMatch(input)) {
      findings.add('url');
    }

    if (_ipRegex.hasMatch(input)) {
      findings.add('ip');
    }

    if (_jwtRegex.hasMatch(input)) {
      findings.add('jwt');
    }

    if (_uuidRegex.hasMatch(input)) {
      findings.add('uuid');
    }

    if (_apiKeyRegex.hasMatch(input)) {
      findings.add('api_key');
    }

    if (_cardRegex.hasMatch(input)) {
      findings.add('credit_card');
    }

    if (_longTokenRegex.hasMatch(input)) {
      findings.add('long_token');
    }

    return findings;
  }
}
