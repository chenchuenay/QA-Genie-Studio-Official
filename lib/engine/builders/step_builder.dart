import 'package:qa_genie/domain/entities/test_step.dart';

class StepBuilder {
  const StepBuilder();

  static List<TestStep> loginPositive() {
    return [
      TestStep(
        // removed const
        action: 'Navigate to the Login page',
        data: '',
        expected: 'Login page loads successfully',
      ),
      TestStep(
        action: 'Enter valid email and password',
        data: 'valid.user@test.com / ValidPassword123',
        expected: 'Credentials are accepted successfully',
      ),
      TestStep(
        action: 'Tap on the Login button',
        data: '',
        expected: 'User is authenticated and redirected to dashboard',
      ),
    ];
  }

  static List<TestStep> loginNegative() {
    return [
      TestStep(
        action: 'Navigate to the Login page',
        data: '',
        expected: 'Login page loads successfully',
      ),
      TestStep(
        action: 'Enter invalid credentials',
        data: 'invalid.user@test.com / WrongPassword',
        expected: 'Authentication request is rejected',
      ),
      TestStep(
        action: 'Submit the login form',
        data: '',
        expected: 'Error message is displayed and login is blocked',
      ),
    ];
  }

  static List<TestStep> apiValidation() {
    return [
      TestStep(
        action: 'Send API request with malformed payload',
        data: '{ invalid_json: true }',
        expected: 'API validates payload structure',
      ),
      TestStep(
        action: 'Inspect API response',
        data: '',
        expected: 'Structured validation error response is returned',
      ),
    ];
  }

  static List<TestStep> securityXss() {
    return [
      TestStep(
        action: 'Open the target input form',
        data: '',
        expected: 'Input form is accessible',
      ),
      TestStep(
        action: 'Inject XSS payload into input field',
        data: '<script>alert("xss")</script>',
        expected: 'Payload is treated as plain text',
      ),
      TestStep(
        action: 'Submit the form',
        data: '',
        expected: 'No script execution occurs in the browser',
      ),
    ];
  }

  static List<TestStep> retrySafety() {
    return [
      TestStep(
        action: 'Trigger operation during unstable connectivity',
        data: '',
        expected: 'Loading state is displayed properly',
      ),
      TestStep(
        action: 'Retry the operation multiple times',
        data: '',
        expected: 'Duplicate processing is prevented',
      ),
      TestStep(
        action: 'Inspect final transaction state',
        data: '',
        expected: 'Only one successful transaction is recorded',
      ),
    ];
  }

  static List<TestStep> genericWorkflow(String feature) {
    return [
      TestStep(
        action: 'Open the $feature workflow',
        data: '',
        expected: '$feature screen loads correctly',
      ),
      TestStep(
        action: 'Perform the primary action in $feature',
        data: '',
        expected: 'System processes the workflow successfully',
      ),
      TestStep(
        action: 'Verify final application state',
        data: '',
        expected: 'Application state updates correctly',
      ),
    ];
  }
}
