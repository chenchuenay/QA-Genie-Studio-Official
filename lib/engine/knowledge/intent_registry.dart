// ============================================================
// INTENT REGISTRY – Central source of truth for intent metadata
// ============================================================
class IntentDefinition {
  final String id;
  final String category;
  final String businessArea;
  final String risk;
  final List<String> keywords;
  final String expectedOutcome;
  final String displayName;
  final Map<String, dynamic> sampleData;

  const IntentDefinition({
    required this.id,
    required this.category,
    required this.businessArea,
    required this.risk,
    required this.keywords,
    required this.expectedOutcome,
    required this.displayName,
    required this.sampleData,
  });
}

class IntentRegistry {
  static final Map<String, IntentDefinition> _intents = {};

  static void register(IntentDefinition intent) {
    _intents[intent.id] = intent;
  }

  static IntentDefinition? get(String id) => _intents[id];

  static List<IntentDefinition> findByCategory(String category) {
    return _intents.values.where((i) => i.category == category).toList();
  }

  static List<IntentDefinition> findByBusinessArea(String businessArea) {
    return _intents.values.where((i) => i.businessArea == businessArea).toList();
  }

  static void loadDefaults() {
    // ========== AUTHENTICATION INTENTS ==========
    // Positive variants
    register(IntentDefinition(
      id: 'auth_positive_valid_credentials',
      category: 'positive',
      businessArea: 'authentication',
      risk: 'MEDIUM',
      keywords: ['valid', 'success', 'login', 'authenticate'],
      expectedOutcome: 'Dashboard loads with user profile',
      displayName: 'Valid login with credentials',
      sampleData: {'email': 'valid.user@example.com', 'password': 'SecurePass123!'},
    ));
    register(IntentDefinition(
      id: 'auth_positive_social_login',
      category: 'positive',
      businessArea: 'authentication',
      risk: 'MEDIUM',
      keywords: ['google', 'facebook', 'social', 'oauth'],
      expectedOutcome: 'User authenticated via provider, dashboard loads',
      displayName: 'Social login with Google',
      sampleData: {'email': 'user@example.com', 'password': 'dummy_social', 'provider': 'google'},
    ));
    register(IntentDefinition(
      id: 'auth_positive_password_reset',
      category: 'positive',
      businessArea: 'authentication',
      risk: 'MEDIUM',
      keywords: ['reset', 'forgot', 'recovery'],
      expectedOutcome: 'Password reset email sent, user can login with new password',
      displayName: 'Password reset flow',
      sampleData: {'email': 'user@example.com', 'password': 'newPass123!', 'resetToken': 'abc123'},
    ));
    register(IntentDefinition(
      id: 'auth_positive_remembered_session',
      category: 'positive',
      businessArea: 'authentication',
      risk: 'MEDIUM',
      keywords: ['remember', 'session', 'persist'],
      expectedOutcome: 'Session persists across browser restart',
      displayName: 'Remembered session persists',
      sampleData: {'email': 'user@example.com', 'password': 'SecurePass123!', 'rememberMe': true},
    ));

    // Negative variants
    register(IntentDefinition(
      id: 'auth_negative_invalid_password',
      category: 'negative',
      businessArea: 'authentication',
      risk: 'MEDIUM',
      keywords: ['invalid', 'wrong', 'fail', 'incorrect'],
      expectedOutcome: 'Error message displayed, login blocked',
      displayName: 'Login fails with invalid password',
      sampleData: {'email': 'user@example.com', 'password': 'wrongpassword'},
    ));
    register(IntentDefinition(
      id: 'auth_negative_locked_account',
      category: 'negative',
      businessArea: 'authentication',
      risk: 'MEDIUM',
      keywords: ['locked', 'suspended', 'disabled'],
      expectedOutcome: 'Account locked message, login impossible',
      displayName: 'Locked account cannot login',
      sampleData: {'email': 'locked@example.com', 'password': 'any'},
    ));
    register(IntentDefinition(
      id: 'auth_negative_nonexistent_user',
      category: 'negative',
      businessArea: 'authentication',
      risk: 'LOW',
      keywords: ['not found', 'does not exist', 'unknown'],
      expectedOutcome: 'Generic error message, no user enumeration',
      displayName: 'Nonexistent user login attempt',
      sampleData: {'email': 'never@example.com', 'password': 'any'},
    ));

    // Validation variants
    register(IntentDefinition(
      id: 'auth_validation_empty_email',
      category: 'validation',
      businessArea: 'authentication',
      risk: 'LOW',
      keywords: ['empty', 'missing', 'required'],
      expectedOutcome: 'Email required validation message',
      displayName: 'Empty email validation',
      sampleData: {'email': '', 'password': '123'},
    ));
    register(IntentDefinition(
      id: 'auth_validation_empty_password',
      category: 'validation',
      businessArea: 'authentication',
      risk: 'LOW',
      keywords: ['empty', 'missing', 'password required'],
      expectedOutcome: 'Password required validation message',
      displayName: 'Empty password validation',
      sampleData: {'email': 'user@example.com', 'password': ''},
    ));
    register(IntentDefinition(
      id: 'auth_validation_invalid_email_format',
      category: 'validation',
      businessArea: 'authentication',
      risk: 'LOW',
      keywords: ['format', 'invalid email', '@'],
      expectedOutcome: 'Email format validation error',
      displayName: 'Invalid email format validation',
      sampleData: {'email': 'not-an-email', 'password': '123'},
    ));

    // Boundary variants
    register(IntentDefinition(
      id: 'auth_boundary_max_email_length',
      category: 'boundary',
      businessArea: 'authentication',
      risk: 'LOW',
      keywords: ['maximum', 'length', 'boundary', 'edge', '250'],
      expectedOutcome: 'Email field enforces max length',
      displayName: 'Email field accepts 250 characters',
      sampleData: {'email': 'a' * 250, 'password': 'pass'},
    ));
    register(IntentDefinition(
      id: 'auth_boundary_max_password_length',
      category: 'boundary',
      businessArea: 'authentication',
      risk: 'LOW',
      keywords: ['maximum', 'password', 'length'],
      expectedOutcome: 'Password field enforces max length',
      displayName: 'Password field handles max length',
      sampleData: {'email': 'user@example.com', 'password': 'b' * 500},
    ));

    // Security variants
    register(IntentDefinition(
      id: 'auth_security_sql_injection',
      category: 'security',
      businessArea: 'authentication',
      risk: 'HIGH',
      keywords: ['sql', 'injection', 'drop', 'select', 'or 1=1'],
      expectedOutcome: 'SQL injection blocked, input sanitized',
      displayName: 'SQL injection in login form',
      sampleData: {'email': "' OR 1=1 --", 'password': 'anything'},
    ));
    register(IntentDefinition(
      id: 'auth_security_xss',
      category: 'security',
      businessArea: 'authentication',
      risk: 'HIGH',
      keywords: ['xss', 'script', '<script>'],
      expectedOutcome: 'XSS payload sanitized, no script execution',
      displayName: 'XSS attempt in login fields',
      sampleData: {'email': '<script>alert(1)</script>', 'password': 'xss'},
    ));

    // Session variants
    register(IntentDefinition(
      id: 'auth_session_expiry',
      category: 'session',
      businessArea: 'authentication',
      risk: 'HIGH',
      keywords: ['expired', 'timeout', 'logout'],
      expectedOutcome: 'User redirected to login page',
      displayName: 'Session expiry after inactivity',
      sampleData: {'token': 'expired_session_token'},
    ));
    register(IntentDefinition(
      id: 'auth_session_concurrent_login',
      category: 'session',
      businessArea: 'authentication',
      risk: 'MEDIUM',
      keywords: ['concurrent', 'multiple', 'sessions'],
      expectedOutcome: 'Old session invalidated or both allowed per policy',
      displayName: 'Concurrent login from different device',
      sampleData: {'sessionId1': 'old_sess', 'sessionId2': 'new_sess'},
    ));

    // ========== E-COMMERCE INTENTS ==========
    register(IntentDefinition(
      id: 'ecom_positive_valid_checkout',
      category: 'positive',
      businessArea: 'ecommerce',
      risk: 'HIGH',
      keywords: ['checkout', 'payment', 'success', 'order'],
      expectedOutcome: 'Order confirmation displayed',
      displayName: 'Successful checkout with valid payment',
      sampleData: {'cart': 'item1,item2', 'paymentMethod': 'credit_card', 'amount': 99.99},
    ));
    register(IntentDefinition(
      id: 'ecom_negative_expired_coupon',
      category: 'negative',
      businessArea: 'ecommerce',
      risk: 'MEDIUM',
      keywords: ['coupon', 'expired', 'discount'],
      expectedOutcome: 'Coupon rejected with error message',
      displayName: 'Expired coupon code rejection',
      sampleData: {'couponCode': 'EXPIRED2023', 'cartTotal': 100},
    ));
    register(IntentDefinition(
      id: 'ecom_security_price_tampering',
      category: 'security',
      businessArea: 'ecommerce',
      risk: 'HIGH',
      keywords: ['price', 'tamper', 'modify', 'discount'],
      expectedOutcome: 'Price validation rejects tampered value',
      displayName: 'Price tampering attempt during checkout',
      sampleData: {'originalPrice': 100, 'tamperedPrice': 1},
    ));

    // ========== BANKING INTENTS ==========
    register(IntentDefinition(
      id: 'bank_positive_transfer',
      category: 'positive',
      businessArea: 'banking',
      risk: 'HIGH',
      keywords: ['transfer', 'send', 'money'],
      expectedOutcome: 'Transfer successful, balance updated',
      displayName: 'Successful money transfer with valid OTP',
      sampleData: {'fromAccount': 'ACC123', 'toAccount': 'ACC456', 'amount': 500, 'otp': '123456'},
    ));
    register(IntentDefinition(
      id: 'bank_negative_invalid_otp',
      category: 'negative',
      businessArea: 'banking',
      risk: 'HIGH',
      keywords: ['otp', 'invalid', 'wrong'],
      expectedOutcome: 'OTP error, transfer blocked',
      displayName: 'Transfer fails due to invalid OTP',
      sampleData: {'fromAccount': 'ACC123', 'toAccount': 'ACC456', 'amount': 500, 'otp': '000000'},
    ));
    register(IntentDefinition(
      id: 'bank_negative_insufficient_funds',
      category: 'negative',
      businessArea: 'banking',
      risk: 'MEDIUM',
      keywords: ['insufficient', 'balance', 'overdraft'],
      expectedOutcome: 'Insufficient funds error, transfer cancelled',
      displayName: 'Insufficient funds for transfer',
      sampleData: {'fromAccount': 'ACC123', 'balance': 100, 'requestedAmount': 200},
    ));
  }
}