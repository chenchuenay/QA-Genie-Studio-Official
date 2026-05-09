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
      return 'The page prevents the unsafe operation, displays a secure validation message, preserves the current user session, and does not expose sensitive implementation details to the user.';
    }
    if (category == 'negative' || category == 'validation') {
      return 'The UI blocks form submission, applies clear focus or error states to the affected fields, maintains all other user input, and provides a specific, actionable error message for recovery.';
    }
    if (category == 'boundary') {
      return 'The application enforces the input limit, keeps the layout responsive without overflow, and displays a character counter or validation indicator describing the accepted range.';
    }
    if (category == 'session') {
      return 'The user session state is correctly maintained according to policy, protected routes remain inaccessible to unauthenticated users, and the UI state reflects the active authentication context.';
    }
    if (domain == 'payment') {
      return 'The checkout flow captures the transaction reference, updates the local application state, and ensures the primary payment button is managed to prevent duplicate processing.';
    }
    return 'The $subject page successfully commits the changes, displays an on-screen confirmation message, and updates the interface to reflect the new state without unexpected disruptions.';
  }

  static String _mobileExpected(
    String category,
    String domain,
    String subject,
  ) {
    if (category == 'security') {
      return 'The app terminates the risky action, ensures sensitive data is removed from the visible screen, and presents a standard system-level notification or controlled recovery view.';
    }
    if (category == 'negative' || category == 'validation') {
      return 'The screen prevents progression, highlights the malformed input with visual or tactile feedback, keeps the input focus on the error field, and provides a clear instruction for correction.';
    }
    if (category == 'boundary') {
      return 'The mobile app enforces the constraint without performance degradation, ensuring that long inputs are properly handled while maintaining standard touch target accessibility.';
    }
    if (category == 'session') {
      return 'The application secure storage is updated with the new session status, background and foreground transitions remain stable, and the user is routed to the appropriate feature module.';
    }
    if (domain == 'payment') {
      return 'The app displays the final payment status, provides a transaction reference for record-keeping, and ensures the UI reflects the updated account balance or status immediately.';
    }
    return 'The $subject screen accepts the user gesture, triggers the appropriate visual transition, and displays a success state with a unique transaction or reference identifier for the operation.';
  }

  static String _apiExpected(String category, String domain, String subject) {
    if (category == 'security') {
      return 'The service rejects the request with an appropriate error status, returns a standard error format without internal implementation details, and generates a verifiable audit record.';
    }
    if (category == 'negative' || category == 'validation') {
      return 'The response returns an appropriate error status code, includes details identifying the invalid parameters, and ensures the underlying resource state remains unmodified.';
    }
    if (category == 'boundary') {
      return 'The API enforces request limits or payload constraints, returning the documented status as appropriate, with clear indicators if the request was throttled.';
    }
    if (category == 'session') {
      return 'The authentication token is validated against the authority, the response includes updated session metadata, and the server rejects subsequent requests using expired credentials.';
    }
    if (domain == 'payment') {
      return 'The response payload includes a unique transaction identifier, the transaction status is correctly updated in the system of record, and the service returns a success status with the resource reference.';
    }
    return 'The $subject endpoint returns a success status code, matches the documented response format, and persists the resource state as verifiable by a subsequent retrieval request.';
  }

  static bool _hasAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}
