import '../ontology/domain_registry.dart';
import '../ontology/domain_data.dart';

class FlowGraphGenerator {
  /// Maps scenario action displayNames to ontology keys where they differ.
  /// This ensures scenarios with actions like "authenticate" or "pay" find
  /// the correct step patterns in DomainRegistry.ontology.
  static const Map<String, String> _actionAliases = {
    // Identity: authenticate/login are semantically the same flow
    'authenticate': 'login',
    'verify': 'login',
    'authorize': 'login',
    // Scheduling: book/create, confirm/create are same flow
    'book': 'create',
    'confirm': 'create',
    // Commerce: pay is the terminal step of checkout
    'pay': 'checkout',
  };

  static const Map<String, String> _platformAliases = {
    'WEB': 'Web',
    'MOBILE': 'Mobile',
    'ANDROID': 'Mobile',
    'IOS': 'Mobile',
  };

  static List<Map<String, String>> generate(
    String domain,
    String action,
    String platform,
    String constraints, {
    String condition = 'valid',
  }) {
    final resolvedAction = _actionAliases[action] ?? action;
    final resolvedPlatform = _platformAliases[platform.toUpperCase()] ?? platform;
    final pattern = DomainRegistry.ontology[domain]?[resolvedAction];
    if (pattern == null) {
      return [{'action': 'Execute $action for $domain', 'data': 'Standard input data', 'expected': 'Operation completes successfully'}];
    }

    final constraintList = constraints.split(',').map((s) => s.trim()).toList();
    for (final req in pattern.requiredConstraints) {
      if (!constraintList.contains(req)) {
        return [{'action': 'Skip action', 'data': 'Constraints not met: $req', 'expected': 'Action skipped'}];
      }
    }

    final dataSamples = DomainData.samples[domain] ?? {};
    final steps = <Map<String, String>>[];
    final actionSteps = pattern.stepsByPlatform[resolvedPlatform] ?? pattern.stepsByPlatform.values.first;

    // Inject condition-specific variation
    final conditionData = condition != 'valid' && condition.isNotEmpty
        ? _conditionDataForStep(action, condition, domain, platform)
        : null;

    for (int i = 0; i < actionSteps.length; i++) {
      final step = actionSteps[i];
      String stepData = dataSamples[step] ?? _generateDataForStep(step, domain, action, i, platform);
      String stepExpected = _generateExpected(step, domain, action, i, actionSteps.length, platform);

      if (conditionData != null) {
        if (conditionData.containsKey('data')) {
          stepData = conditionData['data']!;
        }
        if (conditionData.containsKey('expected')) {
          stepExpected = conditionData['expected']!;
        }
        if (conditionData.containsKey('step_override')) {
          // Replace the entire last step or inject a malicious input step
          if (i == actionSteps.length - 1) {
            stepData = conditionData['step_override']!;
            stepExpected = conditionData['expected'] ?? stepExpected;
          }
        }
      }

      steps.add({
        'action': step,
        'data': stepData,
        'expected': stepExpected,
      });
    }

    return steps;
  }

  /// Returns condition-specific overrides for step data/expected values.
  /// Returns null for positive/valid conditions (no override needed).
  static Map<String, String>? _conditionDataForStep(String action, String condition, String domain, String platform) {
    if (condition == 'sql_injection') {
      return {
        'data': "Inject SQL payload at input field: ' OR 1=1; DROP TABLE users; --",
        'expected': 'Server rejects input with 400 Bad Request; SQL error is not exposed',
      };
    }
    if (condition == 'xss') {
      return {
        'data': 'Inject XSS payload: <script>alert("xss")</script> in name/comment field',
        'expected': 'Payload is HTML-escaped and rendered as text; no script execution occurs',
      };
    }
    if (condition == 'bruteforce') {
      return {
        'data': 'Attempt login with wrong password 5 times: pass1, pass2, ..., pass5',
        'expected': 'Account locked after 5 failed attempts; lockout message shown with retry timer',
      };
    }
    if (condition == 'jwt_hijack') {
      return {
        'data': 'Use forged JWT: header={"alg":"none"} body={"sub":"admin"}',
        'expected': 'Server rejects malformed/forged JWT with 401 Unauthorized',
      };
    }
    if (condition == 'masquerade') {
      return {
        'data': 'Set X-User-ID header to admin@example.com from attacker session',
        'expected': 'Server validates identity and returns 403 Forbidden — privilege escalation blocked',
      };
    }
    if (condition == 'empty') {
      return {
        'data': 'Leave all required fields empty and attempt to submit',
        'expected': 'Validation errors shown for each required field; form not submitted',
      };
    }
    if (condition == 'max_length') {
      return {
        'data': 'Enter 255 characters in name field (max allowed)',
        'expected': 'Field accepts exactly 255 characters; no truncation or error',
      };
    }
    if (condition == 'exceed') {
      return {
        'data': 'Enter 256 characters when max is 255',
        'expected': 'Field rejects with boundary error message; value not accepted',
      };
    }
    if (condition == 'expired') {
      return {
        'data': 'Use expired session token: expired_token_abc123',
        'expected': 'Server returns 401; user redirected to login page',
      };
    }
    if (condition == 'revoked') {
      return {
        'data': 'Use revoked token: revoked_token_def456',
        'expected': 'Server returns 403 Forbidden; token marked as revoked',
      };
    }
    if (condition == 'invalid_format') {
      return {
        'data': 'Enter malformed email: "not-an-email" in email field',
        'expected': 'Inline validation error: "Please enter a valid email address"',
      };
    }
    if (condition == 'special_chars') {
      return {
        'data': 'Enter special chars: <script>alert(1)</script> @!#\$%^&*()',
        'expected': 'Input sanitized; special characters are escaped or rejected with validation error',
      };
    }
    // fallback generic override
    return {
      'data': 'Use condition: $condition for scenario',
      'expected': 'System handles $condition input according to business rules',
    };
  }

  static String _generateDataForStep(String step, String domain, String action, int index, String platform) {
    if (step.contains('Login') || step.contains('Email') || step.contains('Credential')) {
      if (index == 0) return 'Navigate to login page and wait for form to render';
      if (index == 1) return 'admin@demo.com / SecurePass789!';
      return 'Valid credentials authenticated via POST /auth';
    }
    if (step.contains('OTP') || step.contains('Token') || step.contains('Code') || step.contains('Verif')) {
      return 'Enter 6-digit code: 482916 (sent to registered mobile/email)';
    }
    if (step.contains('Amount') || step.contains('Price') || step.contains('Quantity')) {
      return '250.00 (valid range: 1.00 - 9999.99)';
    }
    if (step.contains('Search') || step.contains('Select') || step.contains('Choose') || step.contains('Browse')) {
      return 'Select from dropdown: option matching "headphones" filter';
    }
    if (step.contains('Submit') || step.contains('Confirm') || step.contains('Place') || step.contains('Send')) {
      return 'Complete all required fields and tap confirm';
    }
    if (step.contains('Address') || step.contains('Shipping') || step.contains('Location')) {
      return '42 Maple Drive, Springfield, IL 62701, United States';
    }
    if (step.contains('Payment') || step.contains('Card') || step.contains('Billing')) {
      return 'VISA **** 4242 | Exp: 08/27 | CVV: 345 | Billing matches shipping';
    }
    if (step.contains('Password') || step.contains('Reset') || step.contains('NewPassword')) {
      return 'NewCred#789 / Confirm: NewCred#789 (min 8 chars, 1 special, 1 num)';
    }
    if (step.contains('Date') || step.contains('Schedule') || step.contains('Time')) {
      return 'Start: 2026-07-15 09:00, End: 2026-07-15 17:00 (business hours)';
    }
    if (step.contains('File') || step.contains('Upload') || step.contains('Document') || step.contains('PDF')) {
      return 'Upload: report_Q2_2026.pdf (2.4 MB, application/pdf)';
    }
    if (step.contains('Delete') || step.contains('Remove') || step.contains('Cancel')) {
      return 'Confirm deletion: type "DELETE" in confirmation field';
    }
    if (step.contains('Comment') || step.contains('Note') || step.contains('Description')) {
      return 'Enter text: "Approved after reviewing all test cases. Ready for UAT."';
    }
    if (step.contains('Filter') || step.contains('Sort')) {
      return 'Apply filter: status=active, sortBy=createdDate, order=desc';
    }
    if (step.contains('Error') || step.contains('Invalid') || step.contains('Wrong')) {
      return 'Input: invalid@ / xyz (malformed data for negative testing)';
    }
    if (step.contains('Payload') || step.contains('Request') || step.contains('Trigger') || step.contains('Pipeline')) {
      if (domain == 'Integration' && action == 'send') {
        return 'POST /api/v2/patients/sync with JSON payload: {"eventType":"sync","lastSync":"2026-06-18T00:00:00Z"}';
      }
      if (domain == 'Commerce' && (action == 'add' || action == 'checkout')) {
        return 'POST /cart with {"productId":"SKU-7755","quantity":1}';
      }
    }
    if (step.contains('Dashboard') || step.contains('Landing') || step.contains('Status') || step.contains('Status')) {
      return 'Verify landing page loads with user profile and welcome message visible';
    }
    return _domainAwareData(domain, step, index);
  }

  static String _domainAwareData(String domain, String step, int index) {
    if (domain == 'Identity') {
      if (step.contains('Forgot') || step.contains('Reset')) return 'registered@example.com / new password link';
      return 'user@domain.com / auth payload prepared with credentials';
    }
    if (domain == 'Commerce') {
      if (step.contains('Cart') || step.contains('Bag')) return 'Cart contains Wireless Headphones SKU-7755 — in stock, \$49.99';
      if (step.contains('Shipping') || step.contains('Checkout')) return 'Shipping: 123 Main St, Springfield, IL';
      return 'Product SKU-7755 — in stock, \$49.99';
    }
    if (domain == 'Transaction') return 'From: Savings XXXX-8901, To: Checking XXXX-3456, Amt: 350.00';
    if (domain == 'Scheduling') return 'Date range: 2026-08-01 to 2026-08-05, type: Annual Leave';
    if (domain == 'Records') return 'Record ID: REC-2026-0042, accessible via search';
    if (domain == 'Integration') return 'Webhook URL: https://api.example.com/hooks/v1/trigger';
    return 'Standard input value for step $index';
  }

  static String _generateExpected(String step, String domain, String action, int index, int total, String platform) {
    if (step.startsWith('Verify') || step.startsWith('Check') || step.startsWith('Assert')) {
      if (step.contains('Status') || step.contains('Status')) return 'Build status shows "success" with matching version tag';
      if (step.contains('Badge') || step.contains('Count')) return 'Cart badge updates to show correct item count; UI reflects the change';
      if (step.contains('Dashboard') || step.contains('Landing')) return 'Dashboard loads with user profile data, navigation menu, and recent activity';
      return 'System displays accurate data matching source of truth — no discrepancies';
    }
    if (step.startsWith('Post') || step.startsWith('Send') || step.startsWith('Trigger')) {
      if (platform == 'API') return 'Server responds 200 OK with valid response payload; status code matches expected';
      return 'Request submitted successfully; confirmation received with tracking ID';
    }
    if (step.contains('Submit') || step.contains('Confirm') || step.contains('Place') || step.contains('Order')) {
      return 'Server responds 200 OK with success payload; confirmation UI shown with unique order/reference ID';
    }
    if (step.contains('Error') || step.contains('Fail') || step.contains('Invalid')) {
      return 'Validation error message appears inline; form does not submit; field borders turn red';
    }
    if (step.contains('Login') || step.contains('Sign') || step.contains('Auth')) {
      return 'User is redirected to dashboard/home page with authenticated session and profile visible';
    }
    if (step.contains('OTP') || step.contains('Token') || step.contains('Verif')) {
      return 'System accepts OTP and proceeds to next step; error if expired or wrong';
    }
    if (step.contains('Delete') || step.contains('Remove') || step.contains('Cancel')) {
      return 'Item is permanently removed; confirmation toast shown; list refreshes automatically';
    }
    if (step.contains('Search') || step.contains('Filter') || step.contains('Sort')) {
      return 'List updates to show filtered/sorted results matching criteria; pagination resets if applicable';
    }
    if (step.contains('Upload') || step.contains('File') || step.contains('Document')) {
      return 'File is uploaded successfully; progress bar reaches 100%; thumbnail preview appears';
    }
    if (step.contains('Payment') || step.contains('Pay') || step.contains('Billing')) {
      return 'Payment gateway returns success; receipt generated with transaction ID; balance updates';
    }
    if (step.contains('Select') || step.contains('Choose') || step.contains('Browse') || step.contains('Catalog')) {
      return 'Product list populates with correct items; images and prices load without errors';
    }
    if (step.contains('Menu') || step.contains('Navigate') || step.contains('Open') || step.contains('Go')) {
      return 'Target screen loads within 2 seconds; all UI elements are rendered correctly';
    }
    if (step.contains('Recipient') || step.contains('Beneficiary') || step.contains('Account')) {
      return 'Selected recipient details display correctly; account name and number match selection';
    }
    if (index == total - 1) {
      return 'End-to-end flow completes successfully — all assertions pass with expected outcomes';
    }
    return 'Step completes without error; UI reflects the new state transition';
  }
}
