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
    Map<String, dynamic> testData,
  );
}

class ApiAdapter implements PlatformAdapter {
  @override
  List<TestStep> toSteps(
    List<WorkflowNode> nodes,
    Map<String, dynamic> testData,
  ) {
    final steps = <TestStep>[];
    for (final node in nodes) {
      final step = _resolve(node, testData);
      if (step != null) steps.add(step);
    }
    // Remove consecutive duplicate actions (simple dedup)
    final deduped = <TestStep>[];
    for (var i = 0; i < steps.length; i++) {
      if (i > 0 &&
          steps[i].action == steps[i - 1].action &&
          steps[i].data == steps[i - 1].data) {
        continue;
      }
      deduped.add(steps[i]);
    }
    return deduped;
  }

  TestStep? _resolve(WorkflowNode node, Map<String, dynamic> testData) {
    switch (node.action) {
      case StepAction.navigate:
        // Skip generic navigate when we have a more specific input later
        return null;
      case StepAction.input:
        if (node.entity == EntityType.credentialForm) {
          final email = testData['email'] ?? '';
          final password = testData['password'] ?? '';
          return TestStep(
            action: 'Send login request',
            data: 'email=$email&password=$password',
            expected: 'HTTP 200 OK',
          );
        } else if (node.entity == EntityType.otpCode) {
          final otp = testData['otp'] ?? '';
          return TestStep(
            action: 'Send OTP verification',
            data: 'otp=$otp',
            expected: 'HTTP 200 OK',
          );
        }
        return null;
      case StepAction.select:
        if (node.entity == EntityType.oauthProvider) {
          final provider = testData['provider'] ?? 'unknown';
          return TestStep(
            action: 'Set OAuth provider',
            data: 'provider=$provider',
            expected: 'HTTP 302 Redirect',
          );
        }
        return null;
      case StepAction.submit:
        if (node.entity == EntityType.actionButton) {
          return TestStep(
            action: 'Submit request',
            data: '',
            expected: 'HTTP 200 OK',
          );
        }
        if (node.entity == EntityType.oauthConsent) {
          return TestStep(
            action: 'Grant consent',
            data: '',
            expected: 'HTTP 302 with callback',
          );
        }
        return null;
      case StepAction.wait:
        if (node.entity == EntityType.callback) {
          return TestStep(
            action: 'Wait for callback',
            data: '',
            expected: 'Callback received',
          );
        }
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
            expected: 'Success confirmed',
          );
        }
        if (node.entity == EntityType.sessionToken) {
          return TestStep(
            action: 'Verify session token',
            data: '',
            expected: 'Token is valid',
          );
        }
        if (node.entity == EntityType.errorMessage) {
          return TestStep(
            action: 'Verify error',
            data: '',
            expected: 'Error message displayed',
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
    Map<String, dynamic> testData,
  ) {
    final steps = <TestStep>[];
    for (final node in nodes) {
      final step = _resolve(node, testData);
      if (step != null) steps.add(step);
    }
    return steps;
  }

  TestStep? _resolve(WorkflowNode node, Map<String, dynamic> testData) {
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
            data: '$email / $password',
            expected: 'Input fields accept data',
          );
        }
        return null;
      case StepAction.select:
        if (node.entity == EntityType.oauthProvider) {
          final provider = testData['provider'] ?? 'unknown';
          return TestStep(
            action: 'Click Sign in with $provider',
            data: '',
            expected: 'Redirect to provider consent screen',
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
        if (node.entity == EntityType.oauthConsent) {
          return TestStep(
            action: 'Approve consent',
            data: '',
            expected: 'Redirect back to app',
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
