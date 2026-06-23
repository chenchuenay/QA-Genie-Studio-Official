import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/data/models/test_case_model.dart';

class QaHeuristicsEngine {
  static bool isMeaningfulStep(TestStep step) {
    final action = step.action.toLowerCase().trim();
    final expected = step.expected.toLowerCase().trim();

    // Reject trivial actions
    const weakActions = [
      'open app',
      'click button',
      'submit form',
      'perform action',
      'check result',
      'verify success',
      'inspect state',
      'observe page',
      'perform primary',
    ];
    if (weakActions.any((a) => action.contains(a))) return false;

    // Reject trivial expected
    const weakExpected = [
      'responds correctly',
      'system works',
      'action completes',
      'behaves as expected',
      'successful operation',
      'everything is fine',
      'no errors occur',
    ];

    const edgeCases = [
      'sql injections',
      'unauthorized',
      'xss',
      'session token is invalidated',
      'session fixation',
    ];

    if (edgeCases.any((e) => action.contains(e) || expected.contains(e)))
      return false;

    if (weakExpected.any((e) => expected.contains(e))) return false;

    // Phase 7: Relaxed meaningfulness threshold
    return action.length > 6 && expected.length > 12;
  }

  static int semanticScore(TestCaseModel tc) {
    int score = 0;

    if (tc.title.trim().length > 15) {
      score += 1;
    }

    if (tc.expectedResult.trim().length > 25) {
      score += 1;
    }

    final meaningful = tc.steps.where(isMeaningfulStep).length;

    if (meaningful >= 1) {
      score += 2;
    }

    final combined = '${tc.title} ${tc.expectedResult}'.toLowerCase();

    const weakWords = [
      'works correctly',
      'successful operation',
      'verify system',
      'perform action',
      'check functionality',
    ];

    if (!weakWords.any(combined.contains)) {
      score += 1;
    }

    return score;
  }

  static const List<String> loginRisks = [
    'Session fixation',
    'Credential stuffing',
    'Concurrent login handling',
    'Password visibility leakage',
    'Authentication timeout',
  ];

  static String inferDomain(String module, String feature, String domain) {
    final combined = '$module $feature $domain'.toLowerCase();

    // Define keyword groups for each domain
    const domains = {
      'auth': [
        'login',
        'signup',
        'sign in',
        'password',
        'auth',
        'otp',
        'session',
        'account recovery',
      ],
      'payment': [
        'payment',
        'checkout',
        'card',
        'refund',
        'invoice',
        'subscription',
        'wallet',
      ],
      'file': ['upload', 'download', 'file', 'attachment', 'document', 'image'],
      'discovery': [
        'search',
        'filter',
        'sort',
        'pagination',
        'catalog',
        'listing',
      ],
      'profile': [
        'profile',
        'address',
        'settings',
        'preference',
        'notification',
      ],
    };

    // Calculate scores for each domain
    final scores = <String, int>{};
    for (final entry in domains.entries) {
      final score = entry.value.where((kw) => combined.contains(kw)).length;
      if (score > 0) scores[entry.key] = score;
    }

    if (scores.isEmpty) return 'general';

    // Find highest score, break ties by priority order
    final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
    final candidates = scores.entries
        .where((e) => e.value == maxScore)
        .map((e) => e.key)
        .toList();

    // Priority order: auth > payment > file > discovery > profile
    const priorityOrder = ['auth', 'payment', 'file', 'discovery', 'profile'];
    for (final p in priorityOrder) {
      if (candidates.contains(p)) return p;
    }

    // Fallback (should never reach)
    return candidates.first;
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

    // Prioritize business-critical data integrity over generic category bias
    if (_hasAny(combined, ['payment', 'checkout', 'delete', 'data loss'])) {
      return 'High';
    }

    if (category == 'usability' || category == 'accessibility') {
      return 'Low';
    }

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
      'pinning',
      'api key',
      'clipboard',
      'session',
      'timeout',
      'logout',
      'expiry',
      'expired',
    ]))
      return 'security';
    if (_hasAny(text, [
      'boundary',
      'limit',
      'maximum',
      'minimum',
      'oversized',
      'out-of-range',
    ]))
      return 'boundary';
    if (_hasAny(text, [
      'validation',
      'required',
      'format',
      'missing',
      'malformed',
      'invalid',
    ]))
      return 'validation';
    if (_hasAny(text, [
      'network',
      'connectivity',
      'latency',
      'timeout',
      'offline',
      'online',
      'slow connection',
    ]))
      return 'network_behavior';
    if (_hasAny(text, [
      'navigation',
      'transition',
      'route',
      'page',
      'screen',
      'link',
    ]))
      return 'navigation';
    if (_hasAny(text, [
      'permission',
      'access',
      'grant',
      'deny',
      'allow',
      'ask for permission',
    ]))
      return 'permissions';
    if (_hasAny(text, [
      'accessibility',
      'screen reader',
      'keyboard navigation',
      'focus indicator',
      'tab key',
      'alt text',
      'color contrast',
    ]))
      return 'accessibility';
    if (_hasAny(text, [
      'state persistence',
      'save state',
      'restore state',
      'local storage',
      'session storage',
      'cache',
    ]))
      return 'state_persistence';
    if (_hasAny(text, [
      'failure',
      'reject',
      'blocked',
      'incorrect',
      'negative',
    ]))
      return 'negative';
    if (_hasAny(text, [
      'usability',
      'clarity',
      'interactive elements',
      'ease of use',
    ]))
      return 'usability';
    if (_hasAny(text, ['positive', 'success', 'successful', 'valid']))
      return 'positive';
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
        _hasAny(text, [
          'registration',
          'password reset',
          'checkout',
          'payment',
          'file upload',
          'upload size',
          'numeric inputs',
        ]))
      return false;
    if (_hasAny(context, ['password reset', 'forgot password']) &&
        _hasAny(text, ['registration', 'checkout', 'successful login']))
      return false;
    if (_hasAny(context, ['signup', 'sign up', 'registration']) &&
        _hasAny(text, ['password reset', 'checkout', 'login failure']))
      return false;

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
        return _webExpected(category, inferred, subject, title);
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
      'member can proceed',
      'everything is fine',
      'no errors occur',
      'system is stable',
      'default behaviour',
    ]);
  }

  static String _webExpected(
    String category,
    String domain,
    String subject,
    String title,
  ) {
    if (category == 'security')
      return 'The browser prevents the unsafe operation, displays a secure validation message, maintains the current session security, and ensures no sensitive system details or debug information are visible to the member.';
    if (category == 'negative' || category == 'validation')
      return 'The application blocks the form submission, highlights the invalid fields with an error state, maintains all other member-entered data, and displays a specific, actionable error message (e.g., "Invalid email format") near the affected input.';
    if (category == 'boundary')
      return 'The input field enforces the character limit, prevents further typing once the limit is reached, and displays a "limit reached" indicator or character counter that matches the requirement.';
    if (category == 'session') {
      final text = '$subject $title'.toLowerCase();
      if (_hasAny(text, ['refresh', 'persist']))
        return 'The authenticated session remains active after the browser refresh, the member stays on the protected page, and no duplicate login prompt or lost form state appears.';
      if (_hasAny(text, ['concurrent', 'leakage']))
        return 'Each browser session keeps its own authenticated state, account data from one session never appears in the other session, and logging out from one session does not expose protected data.';
      return 'The application redirects the member to the login page upon session expiry, ensures all local session data is cleared, and verifies that restricted pages are no longer accessible without re-authentication.';
    }
    if (domain == 'payment')
      return 'The checkout page displays a unique transaction reference, updates the history view with the appropriate status, and ensures the payment action is disabled to prevent duplicate processing.';
    return 'The $subject page persists the submitted data, displays a success notification or banner, and the application view updates to reflect the new resource or dashboard state.';
  }

  static String _mobileExpected(
    String category,
    String domain,
    String subject,
  ) {
    if (category == 'security')
      return 'The app terminates the risky action, ensures sensitive data is not visible on the screen, and displays a standard security notification or alert.';
    if (category == 'negative' || category == 'validation')
      return 'The screen prevents progression, provides visual or tactile feedback for the error, highlights the invalid field, and ensures the input method remains available for immediate correction.';
    if (category == 'boundary')
      return 'The app enforces the input constraint without performance lag, ensuring that long inputs are handled gracefully (e.g., truncated or wrapped) within the mobile screen boundaries.';
    if (category == 'session')
      return 'The application session is updated in secure storage, the app transitions smoothly between foreground and background without data loss, and the member is routed to the appropriate start screen if the session is invalid.';
    if (domain == 'payment')
      return 'The app displays the final payment status screen, provides a shareable transaction reference, and updates the local view to reflect the new account or subscription status.';
    return 'The $subject screen accepts the member gesture, performs a smooth visual transition to the success state, and displays a unique reference number for the completed operation.';
  }

  static String _apiExpected(String category, String domain, String subject) {
    if (category == 'security')
      return 'The service rejects the request with an unauthorized or forbidden outcome, returns a standard error message without internal system details, and ensures the attempt is recorded for security monitoring.';
    if (category == 'negative' || category == 'validation')
      return 'The service returns a client error response, provides clear information identifying the invalid inputs, and confirms that the system state was not altered.';
    if (category == 'boundary')
      return 'The service returns a request limit error, indicates that the request was too large or frequent, and ensures the system remains protected.';
    if (category == 'session')
      return 'The service returns a successful authentication result with a secure session identifier, matching the required security structure.';
    if (domain == 'payment')
      return 'The service returns a successful confirmation, includes a unique transaction record, and validates that the requested payment was processed.';
    return 'The $subject endpoint returns a success response, the returned data contains the requested information, and all expected resource fields are present.';
  }

  static bool _hasAny(String text, List<String> terms) =>
      terms.any(text.contains);
}
