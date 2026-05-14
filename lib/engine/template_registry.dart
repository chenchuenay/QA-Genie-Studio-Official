class TemplateRegistry {
  static const Map<String, Map<String, Map<String, dynamic>>>
  platformTemplates = {
    'Web': {
      'positive': {
        'intent_id': 'web_positive_flow',
        'scenarios': [
          'Verify successful login with valid credentials',
          'Verify successful registration with all required fields',
          'Verify successful password reset via email link',
          'Verify successful checkout with multiple payment methods',
        ],
      },
      'negative': {
        'intent_id': 'web_negative_handling',
        'scenarios': [
          'Verify login failure with incorrect password',
          'Verify registration failure with already registered email',
          'Verify password reset failure with non-existent email',
          'Verify checkout failure with invalid payment details',
        ],
      },
      'security': {
        'intent_id': 'web_security_resistance',
        'scenarios': [
          'Verify login form is protected against SQL injection',
          'Verify login form is protected against XSS attacks',
          'Verify session token is invalidated after logout',
          'Verify CSRF token is enforced on sensitive actions',
          'Verify cookie tampering does not grant unauthorized access',
          'Verify session hijacking via stolen token is prevented',
        ],
      },
      'boundary': {
        'intent_id': 'web_boundary_handling',
        'scenarios': [
          'Verify input fields handle maximum character length',
          'Verify numeric inputs reject out-of-range values',
          'Verify file upload size limit is enforced',
        ],
      },
      'validation': {
        'intent_id': 'web_validation',
        'scenarios': [
          'Verify required field validation messages are displayed',
          'Verify email format validation rejects invalid addresses',
          'Verify form submission is blocked with missing fields',
        ],
      },
      'session': {
        'intent_id': 'web_session',
        'scenarios': [
          'Verify session persists after page refresh',
          'Verify session expires after inactivity timeout',
          'Verify concurrent sessions prevent session leakage',
        ],
      },
      'usability': {
        'intent_id': 'web_usability',
        'scenarios': [
          'Verify form navigation using Tab key follows logical order',
          'Verify error messages are announced by screen readers',
        ],
      },
    },
    'Mobile': {
      'positive': {
        'intent_id': 'mobile_positive_flow',
        'scenarios': [
          'Verify successful login with valid biometric authentication',
          'Verify successful registration via mobile OTP',
          'Verify successful password reset using SMS code',
        ],
      },
      'negative': {
        'intent_id': 'mobile_negative_handling',
        'scenarios': [
          'Verify login failure with incorrect fingerprint',
          'Verify registration failure with invalid phone number',
          'Verify payment failure with insufficient balance',
        ],
      },
      'security': {
        'intent_id': 'mobile_security_resistance',
        'scenarios': [
          'Verify app does not store sensitive data in plain text',
          'Verify app does not expose API keys in network requests',
          'Verify root detection blocks app on compromised devices',
          'Verify clipboard is cleared after copying sensitive data',
        ],
      },
      'boundary': {
        'intent_id': 'mobile_boundary_handling',
        'scenarios': [
          'Verify app handles maximum list scrolling without crash',
          'Verify video upload size limit is enforced',
        ],
      },
      'validation': {
        'intent_id': 'mobile_validation',
        'scenarios': [
          'Verify phone number format validation rejects invalid numbers',
          'Verify OTP input field length enforcement',
          'Verify mandatory permission prompts appear when required',
        ],
      },
      'session': {
        'intent_id': 'mobile_session',
        'scenarios': [
          'Verify session persists after app is backgrounded',
          'Verify session expires after app is force-killed',
        ],
      },
      'usability': {
        'intent_id': 'mobile_usability',
        'scenarios': [
          'Verify buttons are large enough for touch targets',
          'Verify app supports landscape orientation without layout break',
        ],
      },
    },
    'API': {
      'positive': {
        'intent_id': 'api_positive_flow',
        'scenarios': [
          'Verify API returns 200 with valid request body',
          'Verify API returns correct data structure for GET request',
          'Verify API returns stable pagination metadata',
        ],
      },
      'negative': {
        'intent_id': 'api_negative_handling',
        'scenarios': [
          'Verify API returns 400 for malformed JSON body',
          'Verify API returns 401 for missing authentication token',
          'Verify API returns 403 for insufficient permissions',
        ],
      },
      'security': {
        'intent_id': 'api_security_resistance',
        'scenarios': [
          'Verify API rejects requests with invalid JWT tokens',
          'Verify API rate limiting is enforced after threshold',
          'Verify API does not expose sensitive data in error responses',
          'Verify JWT token tampering results in 401',
          'Verify replay attacks with used nonce are blocked',
        ],
      },
      'boundary': {
        'intent_id': 'api_boundary_handling',
        'scenarios': [
          'Verify API handles maximum payload size limit',
          'Verify API returns appropriate error for oversized request',
        ],
      },
      'validation': {
        'intent_id': 'api_validation',
        'scenarios': [
          'Verify API validates required fields in request body',
          'Verify API validates data types for each field',
          'Verify API returns descriptive validation error messages',
        ],
      },
      'session': {
        'intent_id': 'api_session',
        'scenarios': [
          'Verify API token refresh works before expiry',
          'Verify API token refresh fails after expiry',
        ],
      },
      'usability': {
        'intent_id': 'api_usability',
        'scenarios': [
          'Verify API response time is under 500ms for typical requests',
          'Verify API documentation matches actual response schema',
        ],
      },
    },
  };
}
