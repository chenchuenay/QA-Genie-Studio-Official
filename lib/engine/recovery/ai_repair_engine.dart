import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/engine/generators/title_generator.dart' as title_gen;
import '../models/scenario.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../ontology/states.dart';

class AiRepairEngine {
  List<WorkingCase> repair(List<WorkingCase> cases, int targetCount) {
    for (final tc in cases) {
      _enrichTitle(tc);
      _enrichExpectedResult(tc);
      _enrichSteps(tc);
      _enrichPreconditions(tc);
      _enrichTestData(tc);
      _enrichPriority(tc);
      _addPlatformLanguage(tc);
    }
    return cases;
  }

  void _enrichTitle(WorkingCase tc) {
    if (tc.title.trim().isEmpty) {
      final scenario = _scenarioFromCase(tc);
      tc.title = title_gen.TitleGenerator.generate(scenario);
    }
  }

  void _enrichExpectedResult(WorkingCase tc) {
    if (tc.expectedResult.trim().isEmpty || tc.expectedResult.trim().length < 20) {
      switch (tc.categoryLock.toLowerCase()) {
        case 'positive':
          if (tc.feature.toLowerCase().contains('login') ||
              tc.module.toLowerCase().contains('auth')) {
            tc.expectedResult =
                'Member is redirected to the dashboard/home page. The top navigation shows the member\'s display name and avatar. A welcome toast confirms successful login. The session token is set and accessible.';
          } else if (tc.feature.toLowerCase().contains('transfer') ||
              tc.feature.toLowerCase().contains('payment')) {
            tc.expectedResult =
                'Transaction completes successfully. A confirmation with a unique transaction ID is displayed. Account balances update to reflect the transfer. A receipt is generated and available for download.';
          } else if (tc.feature.toLowerCase().contains('checkout') ||
              tc.feature.toLowerCase().contains('cart')) {
            tc.expectedResult =
                'Order is placed successfully. A confirmation screen displays the order number, item details, and shipping address. A confirmation email is sent. The cart is cleared after successful placement.';
          } else {
            tc.expectedResult =
                'Operation completes successfully. The system performs the expected state transition. All relevant UI elements update to reflect the new state. A confirmation message is displayed.';
          }
          break;
        case 'negative':
          if (tc.feature.toLowerCase().contains('login')) {
            tc.expectedResult =
                'The form displays a clear error message: "Invalid email or password." No sensitive information about whether the email exists is revealed. The form does not submit. Fields retain their values for correction.';
          } else if (tc.feature.toLowerCase().contains('transfer')) {
            tc.expectedResult =
                'The transfer is rejected with an insufficient funds error. No hold is placed on the account. No OTP is sent. The member can adjust the amount and retry.';
          } else if (tc.feature.toLowerCase().contains('payment') ||
              tc.feature.toLowerCase().contains('checkout')) {
            tc.expectedResult =
                'The transaction is rejected with a clear error message. No charge is processed. The cart/order remains unchanged. The member is prompted to use a different payment method or correct the input.';
          } else {
            tc.expectedResult =
                'System rejects the request with a clear error message. No data mutation occurs. The member can correct the input and retry. The error is logged without exposing sensitive details.';
          }
          break;
        case 'security':
          tc.expectedResult =
              'Malicious input is sanitized or rejected. The API returns 400/403 with a generic error. No sensitive system details are exposed in the response. The security event is logged for monitoring.';
          break;
        case 'validation':
          tc.expectedResult =
              'Inline validation errors appear for each invalid field. Specific error messages describe the issue (e.g., "Please enter a valid email address"). The form does not submit until all errors are resolved.';
          break;
        case 'boundary':
          tc.expectedResult =
              'System handles boundary values gracefully. No crash, truncation, or silent overflow occurs. The input is either accepted within limits or rejected with a clear constraint message.';
          break;
        case 'session':
          tc.expectedResult =
              'The expired session is detected. API returns 401 Unauthorized. Member is redirected to the login page. No data loss occurs — the member\'s in-progress work is preserved. After re-authentication, the member is returned to their previous state.';
          break;
        default:
          tc.expectedResult =
              'Operation completes as expected with correct state transition. All assertions pass.';
      }
    }
  }

  void _enrichSteps(WorkingCase tc) {
    if (tc.steps.isEmpty) {
      final isMobile = tc.platform.toUpperCase() == 'MOBILE';
      final tapVerb = isMobile ? 'Tap' : 'Click';
      tc.steps = [
        TestStep(
          action: 'Navigate to the ${tc.feature} screen',
          data: '',
          expected: '${tc.feature} screen loads with all elements visible',
        ),
        TestStep(
          action: '$tapVerb the primary action button for ${tc.feature}',
          data: tc.testData,
          expected: 'Action is processed',
        ),
        TestStep(
          action: 'Verify the result of the ${tc.feature} operation',
          data: '',
          expected: tc.expectedResult,
        ),
      ];
    } else {
      for (int i = 0; i < tc.steps.length; i++) {
        final step = tc.steps[i];
        if (step.action.trim().isEmpty) {
          final isMobile = tc.platform.toUpperCase() == 'MOBILE';
          step.action = isMobile ? 'Tap action button $i' : 'Click action button $i';
        }
        if (step.expected.trim().isEmpty || step.expected.trim().length < 10) {
          step.expected = i < tc.steps.length - 1
              ? 'Step ${i + 1} completes without error; UI reflects progress'
              : tc.expectedResult.isNotEmpty
                  ? tc.expectedResult
                  : 'Final step completes with expected outcome';
        }
      }
    }
  }

  void _enrichPreconditions(WorkingCase tc) {
    if (tc.preconditions.isEmpty) {
      final isAuth =
          tc.feature.toLowerCase().contains('login') || tc.module.toLowerCase().contains('auth');
      if (isAuth) {
        tc.preconditions = [
          'Member has a registered account with verified email address',
          'Member is on the ${tc.feature} screen with all UI elements rendered',
          'Authentication service is reachable and responding within normal latency',
        ];
      } else if (tc.feature.toLowerCase().contains('checkout') ||
          tc.feature.toLowerCase().contains('cart')) {
        tc.preconditions = [
          'Member is authenticated with an active session',
          'Cart contains at least one in-stock item with valid pricing',
          'Valid shipping address is saved in the address book',
          'Payment gateway is operational and test mode is enabled',
        ];
      } else if (tc.feature.toLowerCase().contains('transfer') ||
          tc.feature.toLowerCase().contains('payment')) {
        tc.preconditions = [
          'Member is authenticated with an active banking session',
          'Source account has sufficient balance for the transaction',
          'Beneficiary/recipient is added and verified',
          'Two-factor authentication is available',
        ];
      } else if (tc.feature.toLowerCase().contains('appointment') ||
          tc.feature.toLowerCase().contains('schedule')) {
        tc.preconditions = [
          'Member is authenticated with an active account',
          'Provider has available slots on the selected date',
          'Insurance information is valid and on file',
        ];
      } else {
        tc.preconditions = [
          'Member is authenticated with an active session and valid role',
          'Member is on the ${tc.feature} screen with all UI elements rendered',
          'Backend services are reachable and responding within normal latency',
        ];
      }
    }

    if (tc.categoryLock.toLowerCase() == 'negative' && !tc.preconditions.any((p) => p.contains('invalid') || p.contains('malformed'))) {
      tc.preconditions.add('Test environment has malformed or out-of-range input data ready');
    }
    if (tc.categoryLock.toLowerCase() == 'security' && !tc.preconditions.any((p) => p.contains('XSS') || p.contains('payload') || p.contains('injection'))) {
      tc.preconditions.add('XSS/CSRF payloads are prepared for injection points');
    }
  }

  void _enrichTestData(WorkingCase tc) {
    if (tc.testData.trim().isEmpty || tc.testData.trim().length < 10) {
      if (tc.feature.toLowerCase().contains('login')) {
        tc.testData = 'email=admin@example.com, password=Secure@Pass789, platform=${tc.platform}';
      } else if (tc.feature.toLowerCase().contains('checkout')) {
        tc.testData = 'item=Wireless Headphones, qty=1, card=VISA-4242, exp=12/28, cvv=345, shipping="123 Main St, Springfield, IL"';
      } else if (tc.feature.toLowerCase().contains('transfer')) {
        tc.testData = 'from=Savings XXXX-8901, to=Checking XXXX-3456, amount=\$250.00, otp=123456';
      } else if (tc.feature.toLowerCase().contains('appointment')) {
        tc.testData = 'date=2026-07-15, time=10:00 AM, provider=Dr. Smith, reason=Annual checkup';
      } else if (tc.feature.toLowerCase().contains('record') || tc.module.toLowerCase().contains('records')) {
        tc.testData = 'recordId=REC-2026-0042, patient=Jane Doe, DOB=1995-03-22';
      } else {
        tc.testData = 'Valid input data per ${tc.feature} specification with realistic values';
      }
    }
  }

  void _enrichPriority(WorkingCase tc) {
    if (tc.priority.isEmpty || tc.priority == 'Medium') {
      final lower = '${tc.module} ${tc.feature} ${tc.title}'.toLowerCase();
      if (lower.contains('payment') ||
          lower.contains('checkout') ||
          lower.contains('transfer') ||
          lower.contains('delete') ||
          lower.contains('login') ||
          lower.contains('authenticate') ||
          lower.contains('password') ||
          lower.contains('data loss') ||
          lower.contains('security') ||
          lower.contains('session')) {
        tc.priority = 'High';
      } else if (lower.contains('negative') ||
          lower.contains('validation') ||
          lower.contains('boundary')) {
        tc.priority = 'Medium';
      } else {
        tc.priority = 'Low';
      }
    }
  }

  void _addPlatformLanguage(WorkingCase tc) {
    final isMobile = tc.platform.toUpperCase() == 'MOBILE';
    final isWeb = tc.platform.toUpperCase() == 'WEB';

    if (isMobile && tc.steps.isNotEmpty) {
      for (final step in tc.steps) {
        if (step.action.startsWith('Click')) {
          step.action = step.action.replaceFirst('Click', 'Tap');
        }
      }
    }
    if (isWeb && tc.steps.isNotEmpty) {
      for (final step in tc.steps) {
        if (step.action.startsWith('Tap')) {
          step.action = step.action.replaceFirst('Tap', 'Click');
        }
      }
    }
  }

  Scenario _scenarioFromCase(WorkingCase tc) {
    EntityType entity = EntityType.member;
    ActionType action = ActionType.login;

    if (tc.feature.toLowerCase().contains('login') ||
        tc.module.toLowerCase().contains('auth')) {
      entity = EntityType.account;
      action = ActionType.login;
    } else if (tc.feature.toLowerCase().contains('checkout') ||
        tc.feature.toLowerCase().contains('cart')) {
      entity = EntityType.cart;
      action = ActionType.checkout;
    } else if (tc.feature.toLowerCase().contains('transfer')) {
      entity = EntityType.transfer;
      action = ActionType.transfer;
    } else if (tc.feature.toLowerCase().contains('appointment') ||
        tc.feature.toLowerCase().contains('schedule')) {
      entity = EntityType.appointment;
      action = ActionType.create;
    } else if (tc.feature.toLowerCase().contains('record')) {
      entity = EntityType.record;
      action = ActionType.view;
    }

    return Scenario(
      entity: entity,
      action: action,
      targetState: StateType.active,
      category: tc.categoryLock.isNotEmpty ? tc.categoryLock : 'positive',
    );
  }
}
