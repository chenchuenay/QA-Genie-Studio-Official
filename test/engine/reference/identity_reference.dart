class IdentityReference {
  static final cases = [
    ReferenceCase(
      title: 'Verify user can successfully log in with valid email and password',
      type: 'POSITIVE',
      priority: 'High',
      preconditions: [
        'User has a registered account with verified email address',
        'User is on the Login screen with email and password fields visible',
        'Account is active (not locked, disabled, or pending verification)',
      ],
      testData: 'email=admin@example.com, password=Secure@Pass789, platform=Web',
      steps: [
        'Navigate to login page at /signin and wait for form to render completely',
        'Enter email: admin@example.com in the Email input field',
        'Enter password: Secure@Pass789 in the Password input field (masked)',
        'Tap Sign In button to submit authentication request',
        'Verify dashboard loads with user profile avatar and welcome message displayed',
      ],
      expectedResult:
          'User is redirected to the dashboard/home page. The top navigation shows the user\'s display name and avatar. A welcome toast notification confirms successful login. The session cookie/token is set and accessible.',
    ),
    ReferenceCase(
      title:
          'Attempt to log in with invalid credentials should display inline validation error',
      type: 'NEGATIVE',
      priority: 'Medium',
      preconditions: [
        'User is on the Login screen',
        'No prior successful authentication session exists',
        'Login form accepts any input without client-side pre-validation',
      ],
      testData: 'email=wrong@example.com, password=InvalidPass1, platform=Web',
      steps: [
        'Navigate to login page at /signin',
        'Enter email: wrong@example.com in the Email field',
        'Enter password: InvalidPass1 in the Password field',
        'Tap Sign In button to attempt authentication',
        'Observe error state: field borders turn red and error message appears inline',
      ],
      expectedResult:
          'The form displays a clear error message: "Invalid email or password. Please try again." No sensitive information (like whether the email exists) is revealed. The form does not submit and fields retain their entered values for correction.',
    ),
    ReferenceCase(
      title:
          'Password reset flow sends reset link for registered email and allows setting new password',
      type: 'POSITIVE',
      priority: 'High',
      preconditions: [
        'User has a registered account with a verified email address',
        'User is on the Login screen and taps "Forgot Password"',
        'Email delivery service is operational',
      ],
      testData:
          'email=user@example.com, newPassword=NewSecure@789, confirmPassword=NewSecure@789, platform=Mobile',
      steps: [
        'Tap "Forgot Password" link below the login form',
        'Enter registered email: user@example.com in the recovery email field',
        'Tap Send Reset Link button',
        'Check email inbox for password reset message (arrives within 30s)',
        'Tap the reset link in the email to open the password reset page',
        'Enter new password: NewSecure@789 in both New Password and Confirm Password fields',
        'Tap Reset Password button to submit',
        'Verify success toast appears: "Your password has been reset successfully"',
        'Navigate back to Login and authenticate with the new password',
      ],
      expectedResult:
          'A password reset email is sent to the registered address within 30 seconds. The reset link opens a secure password reset form. After submitting matching passwords, a success confirmation is displayed. The user can immediately log in with the new password. The old password is invalidated.',
    ),
  ];
}

class ReferenceCase {
  final String title;
  final String type;
  final String priority;
  final List<String> preconditions;
  final String testData;
  final List<String> steps;
  final String expectedResult;

  const ReferenceCase({
    required this.title,
    required this.type,
    required this.priority,
    required this.preconditions,
    required this.testData,
    required this.steps,
    required this.expectedResult,
  });
}
