import 'package:qa_genie/domain/entities/test_step.dart';

class StepBuilder {
  List<TestStep> build({
    required String businessArea,
    required String category,
    required String platform,
    required Map<String, dynamic> testData,
  }) {
    // Dispatch based on business area + category
    if (businessArea == 'authentication') {
      if (category == 'positive') return _authPositiveSteps(platform, testData);
      if (category == 'negative') return _authNegativeSteps(platform, testData);
      if (category == 'validation') return _authValidationSteps(platform, testData);
      if (category == 'boundary') return _authBoundarySteps(platform, testData);
      if (category == 'security') return _authSecuritySteps(platform, testData);
      if (category == 'session') return _authSessionSteps(platform);
    } else if (businessArea == 'ecommerce') {
      if (category == 'positive') return _ecomPositiveSteps(platform, testData);
      if (category == 'negative') return _ecomNegativeSteps(platform, testData);
      if (category == 'security') return _ecomSecuritySteps(platform, testData);
      // fallback for other categories
    } else if (businessArea == 'banking') {
      if (category == 'positive') return _bankingPositiveSteps(platform, testData);
      if (category == 'negative') return _bankingNegativeSteps(platform, testData);
      // etc.
    }
    // Generic fallback
    return _genericSteps(platform, testData);
  }

  // Authentication specific steps
  List<TestStep> _authPositiveSteps(String platform, Map<String, dynamic> testData) {
    if (platform == 'API') {
      return [
        TestStep(action: 'Send login request', data: 'email=${testData['email']}&password=${testData['password']}', expected: 'HTTP 200 OK'),
        TestStep(action: 'Verify response', expected: 'Response contains auth token and user data'),
      ];
    } else {
      return [
        TestStep(action: 'Open login page', expected: 'Login screen displayed'),
        TestStep(action: 'Enter valid email and password', data: '${testData['email']} / ${testData['password']}', expected: 'Input fields accept data'),
        TestStep(action: 'Tap Login button', expected: 'Dashboard loads within 3 seconds'),
      ];
    }
  }

  List<TestStep> _authNegativeSteps(String platform, Map<String, dynamic> testData) {
    if (platform == 'API') {
      return [
        TestStep(action: 'Send login request with wrong password', data: 'email=${testData['email']}&password=${testData['password']}', expected: 'HTTP 401 Unauthorized'),
        TestStep(action: 'Verify error response', expected: 'Error message "Invalid credentials"'),
      ];
    } else {
      return [
        TestStep(action: 'Open login page', expected: 'Login screen displayed'),
        TestStep(action: 'Enter valid email and wrong password', data: '${testData['email']} / ${testData['password']}', expected: 'Error message appears'),
        TestStep(action: 'Verify login blocked', expected: 'User remains on login page'),
      ];
    }
  }

  List<TestStep> _authValidationSteps(String platform, Map<String, dynamic> testData) {
    if (platform == 'API') {
      return [
        TestStep(action: 'Send login request with empty email', data: 'email=&password=123', expected: 'HTTP 400 Bad Request'),
        TestStep(action: 'Verify validation error', expected: 'Error indicates email is required'),
      ];
    } else {
      return [
        TestStep(action: 'Open login page', expected: 'Login screen displayed'),
        TestStep(action: 'Leave email empty, enter password', data: 'password=123', expected: 'Email field highlights as invalid'),
        TestStep(action: 'Attempt login', expected: 'Error: "Email is required"'),
      ];
    }
  }

  List<TestStep> _authBoundarySteps(String platform, Map<String, dynamic> testData) {
    return [
      TestStep(action: 'Enter email of 250 characters', data: testData['email'], expected: 'System accepts or truncates as per spec'),
      TestStep(action: 'Verify no crash', expected: 'Application remains responsive'),
    ];
  }

  List<TestStep> _authSecuritySteps(String platform, Map<String, dynamic> testData) {
    if (platform == 'API') {
      return [
        TestStep(action: 'Send login request with SQL injection', data: 'email=${testData['email']}&password=${testData['password']}', expected: 'HTTP 400 or 403, injection blocked'),
      ];
    } else {
      return [
        TestStep(action: 'Enter SQL injection payload in email field', data: testData['email'], expected: 'Payload sanitized or rejected'),
        TestStep(action: 'Attempt login', expected: 'No SQL error, login fails gracefully'),
      ];
    }
  }

  List<TestStep> _authSessionSteps(String platform) {
    if (platform == 'API') {
      return [
        TestStep(action: 'Wait for token expiry', expected: 'Subsequent API call returns 401'),
      ];
    } else {
      return [
        TestStep(action: 'Wait for session timeout', expected: 'User automatically logged out'),
        TestStep(action: 'Attempt to navigate to protected page', expected: 'Redirected to login'),
      ];
    }
  }

  // E-commerce specific
  List<TestStep> _ecomPositiveSteps(String platform, Map<String, dynamic> testData) {
    if (platform == 'API') {
      return [
        TestStep(action: 'POST /checkout with valid cart', data: testData.toString(), expected: 'HTTP 200, order ID returned'),
      ];
    } else {
      return [
        TestStep(action: 'Add product to cart', expected: 'Cart updates with item'),
        TestStep(action: 'Proceed to checkout', expected: 'Checkout page loads'),
        TestStep(action: 'Enter payment details', data: 'card=${testData['card']}', expected: 'Payment processed'),
        TestStep(action: 'Place order', expected: 'Order confirmation screen appears'),
      ];
    }
  }

  List<TestStep> _ecomNegativeSteps(String platform, Map<String, dynamic> testData) {
    if (platform == 'API') {
      return [
        TestStep(action: 'POST /checkout with expired coupon', data: testData.toString(), expected: 'HTTP 400, coupon invalid error'),
      ];
    } else {
      return [
        TestStep(action: 'Apply expired coupon code', data: testData['coupon'], expected: 'Error message "Coupon expired"'),
        TestStep(action: 'Verify original price remains', expected: 'No discount applied'),
      ];
    }
  }

  List<TestStep> _ecomSecuritySteps(String platform, Map<String, dynamic> testData) {
    return [
      TestStep(action: 'Modify price parameter in request', data: testData.toString(), expected: 'Price validation rejects tampered value'),
    ];
  }

  // Banking specific
  List<TestStep> _bankingPositiveSteps(String platform, Map<String, dynamic> testData) {
    if (platform == 'API') {
      return [
        TestStep(action: 'POST /transfer with valid OTP', data: testData.toString(), expected: 'HTTP 200, transfer completed'),
      ];
    } else {
      return [
        TestStep(action: 'Enter beneficiary details', data: testData['beneficiary'], expected: 'Details accepted'),
        TestStep(action: 'Enter amount and confirm', expected: 'OTP prompt appears'),
        TestStep(action: 'Enter valid OTP', expected: 'Transfer success message'),
      ];
    }
  }

  List<TestStep> _bankingNegativeSteps(String platform, Map<String, dynamic> testData) {
    return [
      TestStep(action: 'Enter invalid OTP', data: testData['otp'], expected: 'Error "Invalid OTP", transfer blocked'),
    ];
  }

  // Generic fallback
  List<TestStep> _genericSteps(String platform, Map<String, dynamic> testData) {
    return [
      TestStep(action: 'Open the target page', expected: 'Page loads'),
      TestStep(action: 'Perform action', data: testData.toString(), expected: 'Action completes'),
      TestStep(action: 'Verify result', expected: 'Expected outcome achieved'),
    ];
  }
}