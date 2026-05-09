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
    if (normalized.trim().length < 35) return true;
    return _hasAny(normalized, [
      'works correctly',
      'as expected',
      'successful operation',
      'operation successful',
      'correct data returned',
      'action completes',
      'outcome is correct',
      'system responds correctly',
    ]);
  }

  static String _webExpected(String category, String domain, String subject) {
    if (category == 'security') {
      return 'The page rejects the unsafe input, displays a controlled validation message, preserves the current user session, and exposes no internal error details.';
    }
    if (category == 'negative' || category == 'validation') {
      return 'The form blocks submission, highlights the affected field, preserves previously entered values, and displays a specific recovery message.';
    }
    if (category == 'boundary') {
      return 'The page enforces the configured limit, keeps the layout stable, and shows a clear message describing the accepted range.';
    }
    if (category == 'session') {
      return 'The browser session state is updated consistently, protected pages remain gated, and navigation reflects the authenticated state.';
    }
    if (domain == 'payment') {
      return 'The checkout page records the transaction state, displays the payment reference, and prevents duplicate submission after confirmation.';
    }
    return 'The $subject page saves the submitted values, displays confirmation, and shows the updated state without losing user input.';
  }

  static String _mobileExpected(
    String category,
    String domain,
    String subject,
  ) {
    if (category == 'security') {
      return 'The app blocks the risky action, keeps sensitive values hidden from local views, and presents a controlled recovery message.';
    }
    if (category == 'negative' || category == 'validation') {
      return 'The screen prevents progression, marks the invalid input, keeps the entered values available for correction, and remains responsive.';
    }
    if (category == 'boundary') {
      return 'The app enforces the limit without freezing, truncating important content, or losing the current screen state.';
    }
    if (category == 'session') {
      return 'The app restores or expires the user session according to policy and routes the user to the correct next screen.';
    }
    if (domain == 'payment') {
      return 'The app shows the payment status, stores the transaction reference, and prevents a second charge from the same action.';
    }
    return 'The $subject screen accepts the user action, displays visible confirmation, and keeps the next available action clear.';
  }

  static String _apiExpected(String category, String domain, String subject) {
    if (category == 'security') {
      return 'The service rejects the request with the documented status code, returns a sanitized error payload, and records a traceable security event.';
    }
    if (category == 'negative' || category == 'validation') {
      return 'The response uses the documented error code, identifies the invalid field, and leaves the persisted resource state unchanged.';
    }
    if (category == 'boundary') {
      return 'The service enforces request limits, returns a documented error envelope when exceeded, and keeps processing time within the accepted threshold.';
    }
    if (category == 'session') {
      return 'The token lifecycle follows policy, returns a documented authentication response, and prevents reuse of expired credentials.';
    }
    if (domain == 'payment') {
      return 'The response includes the transaction reference, persists the final payment state, and prevents duplicate processing for the same idempotency key.';
    }
    return 'The $subject endpoint returns the documented status code, response schema, and persisted resource state for the submitted request.';
  }

  static bool _hasAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}
