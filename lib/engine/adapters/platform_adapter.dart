import 'package:qa_genie/domain/entities/test_step.dart';

enum StepAction {
  navigate,
  input,
  select,
  submit,
  wait,
  verify,
  request,
  validate,
  session,
  security,
}

enum EntityType {
  entryPoint,
  credentialForm,
  actionButton,
  successIndicator,
  errorMessage,
  sessionToken,
  dashboard,
  order,
  receipt,
  item,
  amount,
  recoveryField,
  confirmation,
  timeout,
  sessionStatus,
  oauthProvider,
  oauthConsent,
  callback,
  otpCode,
  priceValidation,
}

class WorkflowNode {
  final StepAction action;
  final EntityType entity;
  final String? dataKey;
  const WorkflowNode({
    required this.action,
    required this.entity,
    this.dataKey,
  });
}

abstract class PlatformAdapter {
  List<TestStep> toSteps(
    List<WorkflowNode> nodes,
    Map<String, dynamic> testData, {
    String outcome = '',
    String constraints = '',
  });
}

class ApiAdapter implements PlatformAdapter {
  @override
  List<TestStep> toSteps(
    List<WorkflowNode> nodes,
    Map<String, dynamic> testData, {
    String outcome = '',
    String constraints = '',
  }) {
    final steps = <TestStep>[];
    for (final node in nodes) {
      final step = _resolve(node, testData, outcome, constraints);
      if (step != null) steps.add(step);
    }
    // Remove consecutive duplicates
    final deduped = <TestStep>[];
    for (int i = 0; i < steps.length; i++) {
      if (i > 0 &&
          steps[i].action == steps[i - 1].action &&
          steps[i].data == steps[i - 1].data)
        continue;
      deduped.add(steps[i]);
    }
    return deduped;
  }

  TestStep? _resolve(
    WorkflowNode node,
    Map<String, dynamic> testData,
    String outcome,
    String constraints,
  ) {
    // API‑specific overrides
    if (outcome == 'empty_email' || outcome == 'empty_password') {
      if (node.entity == EntityType.credentialForm) {
        return TestStep(
          action: 'Send authentication request with empty fields',
          data:
              'email=${testData['email'] ?? ''}&password=${testData['password'] ?? ''}',
          expected: 'HTTP 400 Bad Request with validation error',
        );
      }
    }
    if (outcome == 'invalid_password') {
      if (node.entity == EntityType.credentialForm) {
        return TestStep(
          action: 'Send authentication request with wrong password',
          data:
              'email=${testData['email'] ?? ''}&password=${testData['password'] ?? ''}',
          expected: 'HTTP 401 Unauthorized',
        );
      }
    }
    if (outcome == 'valid_login') {
      if (node.entity == EntityType.credentialForm) {
        return TestStep(
          action: 'Send authentication request',
          data:
              'email=${testData['email'] ?? ''}&password=${testData['password'] ?? ''}',
          expected: 'HTTP 200 OK with auth token',
        );
      }
    }

    // Default API step mapping
    switch (node.action) {
      case StepAction.navigate:
        return null;
      case StepAction.input:
        if (node.entity == EntityType.credentialForm) {
          final email = testData['email'] ?? '';
          final password = testData['password'] ?? '';
          return TestStep(
            action: 'Send request to authentication endpoint',
            data: '{"email": "$email", "password": "$password"}',
            expected: 'HTTP 200 OK or 401',
          );
        }
        return null;
      case StepAction.submit:
        return TestStep(
          action: 'Submit API request',
          data: '',
          expected: 'HTTP 2xx success',
        );
      case StepAction.verify:
        if (node.entity == EntityType.successIndicator) {
          return TestStep(
            action: 'Verify success response',
            data: '',
            expected: 'Response contains success flag and data',
          );
        }
        if (node.entity == EntityType.errorMessage) {
          return TestStep(
            action: 'Verify error response',
            data: '',
            expected: 'Response contains error code and message',
          );
        }
        return null;
      default:
        return null;
    }
  }
}

class WebAdapter implements PlatformAdapter {
  @override
  List<TestStep> toSteps(
    List<WorkflowNode> nodes,
    Map<String, dynamic> testData, {
    String outcome = '',
    String constraints = '',
  }) {
    final steps = <TestStep>[];
    for (final node in nodes) {
      final step = _resolve(node, testData, outcome, constraints);
      if (step != null) steps.add(step);
    }
    return steps;
  }

  TestStep? _resolve(
    WorkflowNode node,
    Map<String, dynamic> testData,
    String outcome,
    String constraints,
  ) {
    // Social login specific
    if (outcome == 'social_login') {
      if (node.entity == EntityType.credentialForm) return null;
      if (node.entity == EntityType.oauthProvider) {
        final provider = testData['provider'] ?? 'Google';
        return TestStep(
          action: 'Click "Sign in with $provider" button',
          data: '',
          expected: 'Redirected to $provider consent screen',
        );
      }
      if (node.entity == EntityType.oauthConsent) {
        return TestStep(
          action: 'Approve consent',
          data: '',
          expected: 'Redirected back to application',
        );
      }
      if (node.action == StepAction.wait &&
          node.entity == EntityType.callback) {
        return TestStep(
          action: 'Wait for OAuth callback',
          data: '',
          expected: 'Callback URL invoked with authorization code',
        );
      }
    }

    // Validation: empty email / password
    if (outcome == 'empty_email' && node.entity == EntityType.credentialForm) {
      return TestStep(
        action: 'Leave email field empty',
        data: 'email=',
        expected: 'Email field is empty',
      );
    }
    if (outcome == 'empty_password' &&
        node.entity == EntityType.credentialForm) {
      return TestStep(
        action: 'Leave password field empty',
        data: 'password=',
        expected: 'Password field is empty',
      );
    }

    // Default Web step generation
    switch (node.action) {
      case StepAction.navigate:
        return TestStep(
          action: 'Open page',
          data: '',
          expected: 'Page loads successfully',
        );
      case StepAction.input:
        if (node.entity == EntityType.credentialForm) {
          final email = testData['email'] ?? '';
          final password = testData['password'] ?? '';
          return TestStep(
            action: 'Enter credentials',
            data: '$email / [PROTECTED]',
            expected: 'Input fields accept the values',
          );
        }
        return null;
      case StepAction.select:
        if (node.entity == EntityType.item) {
          return TestStep(
            action: 'Select item',
            data: '',
            expected: 'Item is highlighted',
          );
        }
        return null;
      case StepAction.submit:
        if (node.entity == EntityType.actionButton) {
          return TestStep(
            action: 'Click button',
            data: '',
            expected: 'Action submitted',
          );
        }
        return null;
      case StepAction.wait:
        if (node.entity == EntityType.timeout) {
          return TestStep(
            action: 'Wait for timeout',
            data: '',
            expected: 'Session expires',
          );
        }
        return null;
      case StepAction.verify:
        if (node.entity == EntityType.successIndicator) {
          return TestStep(
            action: 'Verify success',
            data: '',
            expected: 'Success message appears',
          );
        }
        if (node.entity == EntityType.errorMessage) {
          return TestStep(
            action: 'Verify error',
            data: '',
            expected: 'Error message is displayed',
          );
        }
        if (node.entity == EntityType.sessionToken) {
          return TestStep(
            action: 'Verify session',
            data: '',
            expected: 'Session cookie is set',
          );
        }
        return null;
      default:
        return null;
    }
  }
}

class MobileAdapter implements PlatformAdapter {
  @override
  List<TestStep> toSteps(
    List<WorkflowNode> nodes,
    Map<String, dynamic> testData, {
    String outcome = '',
    String constraints = '',
  }) {
    final steps = <TestStep>[];
    for (final node in nodes) {
      final step = _resolve(node, testData, outcome, constraints);
      if (step != null) steps.add(step);
    }
    return steps;
  }

  TestStep? _resolve(
    WorkflowNode node,
    Map<String, dynamic> testData,
    String outcome,
    String constraints,
  ) {
    // Social login (mobile)
    if (outcome == 'social_login') {
      if (node.entity == EntityType.credentialForm) return null;
      if (node.entity == EntityType.oauthProvider) {
        final provider = testData['provider'] ?? 'Google';
        return TestStep(
          action: 'Tap "Sign in with $provider" button',
          data: '',
          expected: 'Redirect to $provider consent screen',
        );
      }
      if (node.entity == EntityType.oauthConsent) {
        return TestStep(
          action: 'Approve consent',
          data: '',
          expected: 'Redirect back to app',
        );
      }
      if (node.action == StepAction.wait &&
          node.entity == EntityType.callback) {
        return TestStep(
          action: 'Wait for OAuth callback',
          data: '',
          expected: 'Callback received, app resumes',
        );
      }
    }

    // Validation (empty fields)
    if (outcome == 'empty_email' && node.entity == EntityType.credentialForm) {
      return TestStep(
        action: 'Leave email field empty',
        data: 'email=',
        expected: 'Email field is empty',
      );
    }
    if (outcome == 'empty_password' &&
        node.entity == EntityType.credentialForm) {
      return TestStep(
        action: 'Leave password field empty',
        data: 'password=',
        expected: 'Password field is empty',
      );
    }

    // Default mobile actions
    switch (node.action) {
      case StepAction.navigate:
        return TestStep(
          action: 'Open app to relevant screen',
          data: '',
          expected: 'Screen loads successfully',
        );
      case StepAction.input:
        if (node.entity == EntityType.credentialForm) {
          final email = testData['email'] ?? '';
          final password = testData['password'] ?? '';
          return TestStep(
            action: 'Enter credentials',
            data: '$email / [PROTECTED]',
            expected: 'Input fields accept the values',
          );
        }
        return null;
      case StepAction.select:
        if (node.entity == EntityType.item) {
          return TestStep(
            action: 'Tap on item',
            data: '',
            expected: 'Item is selected',
          );
        }
        return null;
      case StepAction.submit:
        if (node.entity == EntityType.actionButton) {
          return TestStep(
            action: 'Tap submit button',
            data: '',
            expected: 'Action is processed',
          );
        }
        return null;
      case StepAction.wait:
        if (node.entity == EntityType.timeout) {
          return TestStep(
            action: 'Wait for session to expire',
            data: '',
            expected: 'App returns to login screen',
          );
        }
        return null;
      case StepAction.verify:
        if (node.entity == EntityType.successIndicator) {
          return TestStep(
            action: 'Verify success message',
            data: '',
            expected: 'Success toast or modal appears',
          );
        }
        if (node.entity == EntityType.errorMessage) {
          return TestStep(
            action: 'Verify error message',
            data: '',
            expected: 'Error dialog or inline message shown',
          );
        }
        if (node.entity == EntityType.sessionToken) {
          return TestStep(
            action: 'Verify session persistence',
            data: '',
            expected: 'User stays logged in after app restart',
          );
        }
        return null;
      default:
        return null;
    }
  }
}
