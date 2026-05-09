class QaHeuristicsEngine {
  static const List<String> loginRisks = [
    'Session fixation',
    'Credential stuffing',
    'Concurrent login handling',
    'Password visibility leakage',
    'Authentication timeout',
  ];

  static String inferDomain(String module, String feature, String domain) {
    final combined = '$module $feature $domain'.toLowerCase();
    if (_hasAny(combined, [
      'login',
      'signup',
      'sign in',
      'password',
      'auth',
      'otp',
      'session',
      'account recovery',
    ])) {
      return 'auth';
    }
    if (_hasAny(combined, [
      'payment',
      'checkout',
      'card',
      'refund',
      'invoice',
      'subscription',
      'wallet',
    ])) {
      return 'payment';
    }
    if (_hasAny(combined, [
      'upload',
      'download',
      'file',
      'attachment',
      'document',
      'image',
    ])) {
      return 'file';
    }
    if (_hasAny(combined, [
      'search',
      'filter',
      'sort',
      'pagination',
      'catalog',
      'listing',
    ])) {
      return 'discovery';
    }
    if (_hasAny(combined, [
      'profile',
      'address',
      'settings',
      'preference',
      'notification',
    ])) {
      return 'profile';
    }
    return 'general';
  }

  static String priorityFor({
    required String category,
    required String module,
    required String feature,
    required String title,
    required String platform,
    String domain = 'general',
  }) {
    final inferred = inferDomain(module, feature, domain);
    final combined = '$module $feature $title $platform $inferred'
        .toLowerCase();

    if (category == 'security' ||
        category == 'session' ||
        _hasAny(combined, [
          'payment',
          'checkout',
          'auth',
          'login',
          'password',
          'permission',
          'token',
          'privacy',
          'data loss',
          'unauthorized',
          'refund',
          'delete',
        ])) {
      return 'High';
    }

    if (category == 'usability' &&
        !_hasAny(combined, ['accessibility', 'screen reader', 'blocked'])) {
      return 'Low';
    }

    if (category == 'boundary' || category == 'validation') return 'Medium';
    if (category == 'negative') return 'Medium';
    return 'Medium';
  }

  static String inferCategory(String rawCategory, String title) {
    final category = rawCategory.toLowerCase();
    final text = '$category $title'.toLowerCase();
    if (_hasAny(text, [
      'security',
      'xss',
      'sql',
      'csrf',
      'token',
      'unauthorized',
      'tamper',
      'replay',
      'mitm',
    ])) {
      return 'security';
    }
    if (_hasAny(text, ['session', 'timeout', 'logout', 'expiry', 'expired'])) {
      return 'session';
    }
    if (_hasAny(text, [
      'boundary',
      'limit',
      'maximum',
      'minimum',
      'oversized',
      'out-of-range',
    ])) {
      return 'boundary';
    }
    if (_hasAny(text, [
      'validation',
      'required',
      'format',
      'missing',
      'malformed',
      'invalid',
    ])) {
      return 'validation';
    }
    if (_hasAny(text, [
      'failure',
      'reject',
      'blocked',
      'incorrect',
      'negative',
    ])) {
      return 'negative';
    }
    if (_hasAny(text, [
      'usability',
      'accessibility',
      'screen reader',
      'touch target',
    ])) {
      return 'usability';
    }
    if (_hasAny(text, ['positive', 'success', 'successful', 'valid'])) {
      return 'positive';
    }
    return category.isEmpty || category == 'functional' ? 'positive' : category;
  }

  static bool scenarioMatchesContext(
    String scenario,
    String module,
    String feature,
    String domain,
  ) {
    final text = scenario.toLowerCase();
    final context = '$module $feature'.toLowerCase();

    if (_hasAny(context, ['login', 'sign in']) &&
        _hasAny(text, ['registration', 'password reset', 'checkout'])) {
      return false;
    }
    if (_hasAny(context, ['password reset', 'forgot password']) &&
        _hasAny(text, ['registration', 'checkout', 'successful login'])) {
      return false;
    }
    if (_hasAny(context, ['signup', 'sign up', 'registration']) &&
        _hasAny(text, ['password reset', 'checkout', 'login failure'])) {
      return false;
    }

    switch (domain) {
      case 'auth':
        return !_hasAny(text, [
          'checkout',
          'payment',
          'card',
          'refund',
          'upload',
          'file',
          'pagination',
        ]);
      case 'payment':
        return !_hasAny(text, [
          'login',
          'registration',
          'password reset',
          'biometric',
          'otp',
          'profile',
          'upload',
        ]);
      case 'file':
        return !_hasAny(text, [
          'login',
          'checkout',
          'payment',
          'card',
          'password',
          'token refresh',
        ]);
      case 'discovery':
        return !_hasAny(text, [
          'login',
          'checkout',
          'payment',
          'password',
          'registration',
        ]);
      case 'profile':
        return !_hasAny(text, [
          'checkout',
          'payment',
          'card',
          'pagination',
          'file upload',
        ]);
      default:
        return true;
    }
  }

  static String expectedResult({
    required String platform,
    required String category,
    required String module,
    required String feature,
    required String title,
    String domain = 'general',
  }) {
    final inferred = inferDomain(module, feature, domain);
    final subject = feature.isNotEmpty ? feature : module;

    switch (platform) {
      case 'API':
        return _apiExpected(category, inferred, subject);
      case 'Mobile':
        return _mobileExpected(category, inferred, subject);
      default:
        return _webExpected(category, inferred, subject);
    }
  }

  static bool hasWeakExpectedResult(String text) {
    final normalized = text.toLowerCase();
    if (normalized.trim().length < 45) return true;
    return _hasAny(normalized, [
      'works correctly',
      'as expected',
      'successful operation',
      'operation successful',
      'correct data returned',
      'action completes',
      'outcome is correct',
      'system responds correctly',
      'appropriate response',
      'user can proceed',
      'everything is fine',
      'no errors occur',
      'system is stable',
      'default behaviour',
    ]);
  }

  static String _webExpected(String category, String domain, String subject) {
    if (category == 'security') {
      return 'The browser prevents the unsafe operation, displays a secure validation message in the DOM, preserves the current user session cookie, and ensures no sensitive implementation details or stack traces are visible in the UI or console.';
    }
    if (category == 'negative' || category == 'validation') {
      return 'The application blocks the form submission, applies the "error" CSS class to the invalid fields, maintains all other user-entered data, and displays a specific, actionable error message (e.g., "Invalid email format") near the affected input.';
    }
    if (category == 'boundary') {
      return 'The input field enforces the character limit at the DOM level, prevents further typing, and displays a "limit reached" indicator or character counter that matches the defined boundary requirements.';
    }
    if (category == 'session') {
      return 'The application redirects the user to the login page upon session expiry, clears local storage/session storage as per policy, and ensures that restricted routes return a 401/403 equivalent UI state.';
    }
    if (domain == 'payment') {
      return 'The checkout page displays a unique transaction reference ID, updates the "Order History" view with a "Pending" or "Success" status, and disables the payment button to prevent race conditions or duplicate charges.';
    }
    return 'The $subject page persists the submitted data, displays a green success toast or banner with a unique ID, and the browser URL updates to reflect the new resource or dashboard state.';
  }

  static String _mobileExpected(
    String category,
    String domain,
    String subject,
  ) {
    if (category == 'security') {
      return 'The app terminates the risky action, clears sensitive data from the view hierarchy (preventing screen scraping), and displays a system-level alert or standard security notification.';
    }
    if (category == 'negative' || category == 'validation') {
      return 'The screen prevents progression, triggers a haptic feedback pulse, highlights the invalid field with a red border, and ensures the on-screen keyboard remains active for immediate correction.';
    }
    if (category == 'boundary') {
      return 'The mobile app enforces the input constraint without UI lag, ensuring that long strings are truncated with ellipses "..." or wrapped correctly within the viewport without breaking the layout.';
    }
    if (category == 'session') {
      return 'The application secure storage (Keychain/Keystore) is updated, the app transitions smoothly between foreground/background without session loss, and the user is routed to the "Get Started" screen if the session is invalid.';
    }
    if (domain == 'payment') {
      return 'The app displays the final "Payment Successful" screen, provides a shareable transaction receipt, and the local database is updated to reflect the new account balance or subscription tier.';
    }
    return 'The $subject screen accepts the user gesture (tap/swipe), triggers a smooth Hero transition to the success state, and displays a unique reference number (e.g., APP-REF-XXXX) for the completed operation.';
  }

  static String _apiExpected(String category, String domain, String subject) {
    if (category == 'security') {
      return 'The service rejects the request with a 401 Unauthorized or 403 Forbidden status code, returns a standard RFC-compliant error body, and logs the attempt with a unique request-id for security auditing.';
    }
    if (category == 'negative' || category == 'validation') {
      return 'The server returns a 400 Bad Request or 422 Unprocessable Entity status, includes a JSON body with a "validation_errors" array, and ensures the database state remains unmodified.';
    }
    if (category == 'boundary') {
      return 'The API returns a 413 Payload Too Large or 429 Too Many Requests status, including appropriate "Retry-After" headers and a message indicating the specific quota or limit breached.';
    }
    if (category == 'session') {
      return 'The response returns a 200 OK or 201 Created with a valid "access_token" (JWT) and "refresh_token" in the JSON payload, matching the documented authentication schema.';
    }
    if (domain == 'payment') {
      return 'The response returns a 201 Created status, includes a "transaction_id" (UUID v4), and the "status" field in the response body is set to "captured" or "processed".';
    }
    return 'The $subject endpoint returns a 200 OK status code, the response body contains the requested resource with all mandatory fields populated, and the "Cache-Control" headers are correctly set.';
  }

  static bool _hasAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}
