// ============================================================

// FILE: lib/engine/builders/expected_result_builder.dart

// ============================================================

class ExpectedResultBuilder {
  const ExpectedResultBuilder();

  static String loginSuccess() =>
      'User is redirected to dashboard and authenticated session is created.';

  static String loginFailure(String reason) =>
      'Error message "$reason" appears below the password field, and login is blocked.';

  static String requiredField(String field) =>
      'Validation error near $field field prevents form submission.';

  static String xssBlocked() =>
      'Payload is rendered as plain text and no script execution occurs.';

  static String sqlInjectionBlocked() =>
      'Input is treated as literal text; SQL query is not executed and error is returned.';

  static String tokenExpiry() =>
      'Authentication fails with expired token, and user is redirected to login page.';

  static String apiSuccess() =>
      'API responds with successful status code and expected schema structure.';

  static String apiValidationFailure() =>
      'API rejects invalid payload and returns structured validation response.';

  static String sessionTimeout() =>
      'Expired session is invalidated and user access is blocked securely.';

  static String retryHandled() =>
      'System safely retries the operation without duplicate processing.';

  static String duplicateBlocked() =>
      'Duplicate request is identified and prevented from creating duplicate records.';

  static String paymentProcessed() =>
      'Payment transaction is completed successfully and confirmation is generated.';

  static String unauthorizedAccessBlocked() =>
      'Unauthorized access attempt is rejected without exposing sensitive information.';

  static String networkRecovery() =>
      'Application recovers gracefully after temporary connectivity interruption.';

  static String genericSuccess(String feature) =>
      '$feature workflow completes successfully and application state remains stable.';
}
