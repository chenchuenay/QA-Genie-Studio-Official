
class ExpectedResultBuilder {
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
}
