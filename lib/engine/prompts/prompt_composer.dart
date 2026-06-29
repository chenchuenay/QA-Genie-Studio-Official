import 'dart:convert';

class PromptComposer {
  const PromptComposer();

  static String compose({
    required String module,
    required String feature,
    required String platform,
    required List<Map<String, dynamic>> skeletons,
    String? constraints,
    String domain = 'general',
  }) {
    final buffer = StringBuffer();

    // Dynamic context
    buffer.writeln(
      _buildContextBlock(
        module: module,
        feature: feature,
        platform: platform,
        constraints: constraints,
        domain: domain,
      ),
    );

    // Dynamic skeleton plan
    buffer.writeln(_buildSkeletonBlock(skeletons));

    // JSON contract example (helps model understand schema)
    buffer.writeln(_buildJsonContract(domain, platform));

    // Final instruction
    buffer.writeln('''
FINAL EXECUTION RULE:

Return ONLY valid JSON array.

No explanations.

No markdown.
''');

    return buffer.toString();
  }

  static String _buildContextBlock({
    required String module,
    required String feature,
    required String platform,
    required String domain,
    String? constraints,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('\n=== CONTEXT ===');
    buffer.writeln('DOMAIN: $domain');
    buffer.writeln('PLATFORM: $platform');
    buffer.writeln('MODULE: $module');
    buffer.writeln('FEATURE: $feature');
    if (constraints != null && constraints.trim().isNotEmpty) {
      buffer.writeln('CONSTRAINTS: ${constraints.trim()}');
    }
    return buffer.toString();
  }

  static String _buildSkeletonBlock(List<Map<String, dynamic>> skeletons) {
    final buffer = StringBuffer();
    buffer.writeln('\n=== GENERATION PLAN ===');
    buffer.writeln('Generate EXACTLY ${skeletons.length} testcases.');
    buffer.writeln('STRICT CATEGORY LOCKING ENABLED.');
    for (int i = 0; i < skeletons.length; i++) {
      final sk = skeletons[i];
      buffer.writeln('''
CASE ${i + 1}
CATEGORY: ${sk['category']}
TYPE: ${sk['type']}
PRIORITY: ${sk['priority']}
INTENT: ${sk['intent_id']}
TITLE_DIRECTION: ${sk['title']}
''');
    }
    return buffer.toString();
  }

  static String _actionText(String platform, String web, String mobile, String api) {
    final p = platform.toLowerCase();
    if (p == 'mobile') return mobile;
    if (p == 'api') return api;
    return web;
  }

  static Map<String, dynamic> _emailAuthContract(String platform) {
    final action = _actionText(
      platform,
      'Navigate to login page',
      'Open app and navigate to login screen',
      'Send POST /api/v1/auth/login with credentials',
    );
    return {
      "id": "TC_LOGIN_001",
      "title": "Valid login succeeds",
      "module": "Login",
      "feature": "Member login",
      "platform": platform.toUpperCase(),
      "preconditions": ["Member account exists", "Application is accessible"],
      "testData": "email=test@example.com&password=ValidPass1!",
      "steps": [
        {"action": action, "data": "", "expected": "Login page loads successfully"},
      ],
      "expectedResult": "Member is authenticated and redirected to dashboard",
      "priority": "High",
      "type": "POSITIVE",
      "categoryLock": "positive",
      "intent_id": "valid_login",
    };
  }

  static Map<String, dynamic> _oauthContract(String platform) {
    final action = _actionText(
      platform,
      'Click Sign in with Google',
      'Tap Sign in with Google on login screen',
      'Send POST /api/v1/auth/google with authorization code',
    );
    return {
      "id": "TC_OAUTH_001",
      "title": "Google login succeeds",
      "module": "Login",
      "feature": "Social login",
      "platform": platform.toUpperCase(),
      "preconditions": ["Browser supports third-party cookies", "Application is accessible"],
      "testData": "provider=google&authCode=AUTH_CODE_123&redirectUri=https://app.example.com/callback",
      "steps": [
        {"action": action, "data": "provider=google", "expected": "Google OAuth consent screen appears"},
      ],
      "expectedResult": "User is authenticated via Google and redirected to dashboard",
      "priority": "High",
      "type": "POSITIVE",
      "categoryLock": "positive",
      "intent_id": "valid_social_login",
    };
  }

  static Map<String, dynamic> _apiKeyContract(String platform) {
    final action = _actionText(
      platform,
      'Send authenticated API request',
      'Make authenticated API call from app',
      'Send GET /api/v1/resource with Authorization: Bearer sk_test_abc123',
    );
    return {
      "id": "TC_API_001",
      "title": "Valid API key returns resource",
      "module": "API",
      "feature": "Authentication",
      "platform": platform.toUpperCase(),
      "preconditions": ["API endpoint is accessible", "Valid API key exists"],
      "testData": "apiKey=sk_test_abc123&endpoint=/api/v1/resource&method=GET",
      "steps": [
        {"action": action, "data": "headers=Authorization:Bearer sk_test_abc123", "expected": "HTTP 200 OK with valid response body"},
      ],
      "expectedResult": "API returns 200 OK with requested resource data",
      "priority": "High",
      "type": "POSITIVE",
      "categoryLock": "positive",
      "intent_id": "valid_api_key",
    };
  }

  static Map<String, dynamic> _samlContract(String platform) {
    final action = _actionText(
      platform,
      'Initiate SAML login from application',
      'Tap SAML login button on app',
      'Send POST /api/v1/auth/saml with SAML response',
    );
    return {
      "id": "TC_SAML_001",
      "title": "Valid SAML assertion authenticates user",
      "module": "Auth",
      "feature": "SAML SSO",
      "platform": platform.toUpperCase(),
      "preconditions": ["IdP is reachable", "Valid SAML assertion exists"],
      "testData": "samlAssertion=ENCRYPTED_SAML_RESPONSE&acsUrl=https://app.example.com/saml/acs&entityId=urn:example:app",
      "steps": [
        {"action": action, "data": "entityId=urn:example:app", "expected": "Redirected to IdP login page"},
      ],
      "expectedResult": "User is authenticated via SAML SSO and redirected to dashboard",
      "priority": "High",
      "type": "POSITIVE",
      "categoryLock": "positive",
      "intent_id": "valid_saml_auth",
    };
  }

  static Map<String, dynamic> _genericContract(String platform) {
    final action = _actionText(
      platform,
      'Perform primary action',
      'Perform primary action on app',
      'Send request to target endpoint',
    );
    return {
      "id": "TC_001",
      "title": "Valid input produces expected output",
      "module": "Module",
      "feature": "Feature",
      "platform": platform.toUpperCase(),
      "preconditions": ["System is accessible", "User is authorized"],
      "testData": "valid_input_1=value1&valid_input_2=value2",
      "steps": [
        {"action": action, "data": "", "expected": "System responds as expected"},
      ],
      "expectedResult": "Operation completes successfully",
      "priority": "Medium",
      "type": "POSITIVE",
      "categoryLock": "positive",
      "intent_id": "valid_scenario",
    };
  }

  static String _buildJsonContract(String domain, String platform) {
    Map<String, dynamic> schema;
    switch (domain) {
      case 'emailAuth':
        schema = _emailAuthContract(platform);
        break;
      case 'oauthSocial':
        schema = _oauthContract(platform);
        break;
      case 'apiKey':
        schema = _apiKeyContract(platform);
        break;
      case 'samlSso':
        schema = _samlContract(platform);
        break;
      default:
        schema = _genericContract(platform);
    }
    return '\n=== JSON CONTRACT ===\n${jsonEncode([schema])}';
  }
}
