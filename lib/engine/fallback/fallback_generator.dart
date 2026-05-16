import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/core/utils/test_data_factory.dart';

class FallbackGenerator {
  static List<TestCaseModel> generate({
    required int count,
    required String module,
    required String feature,
    required String platform,
  }) {
    final resolvedFeature = feature.trim().isNotEmpty ? feature : module;
    final context = '$module $feature'.toLowerCase();
    final loginMatcher = RegExp(
      r'\b(login|sign[ -]?in|signin|auth|authentication|logout|register|sign[ -]?up)\b',
    );
    final candidates = loginMatcher.hasMatch(context)
        ? _authCases(module, resolvedFeature, platform)
        : _genericCases(module, resolvedFeature, platform);

    final cases = <TestCaseModel>[];
    final seen = <String>{};

    for (final tc in candidates) {
      final key = tc.title.toLowerCase().trim();
      if (seen.add(key)) cases.add(tc);
      if (cases.length >= count) return cases;
    }

    var variant = 1;
    while (cases.length < count) {
      final tc = _variantCase(
        module: module,
        feature: resolvedFeature,
        platform: platform,
        variant: variant++,
      );
      final key = tc.title.toLowerCase().trim();
      if (seen.add(key)) cases.add(tc);
    }

    return cases.take(count).toList();
  }

  static List<TestCaseModel> _authCases(
    String module,
    String feature,
    String platform,
  ) {
    switch (platform) {
      case 'API':
        return _authApiCases(module, feature, platform);
      case 'Mobile':
        return _authMobileCases(module, feature, platform);
      default:
        return _authWebCases(module, feature, platform);
    }
  }

  static List<TestCaseModel> _authWebCases(
    String module,
    String feature,
    String platform,
  ) {
    final validEmail = TestDataFactory.validEmail('$feature-valid');
    final lockedEmail = TestDataFactory.validEmail('$feature-locked');
    final activeEmail = TestDataFactory.validEmail('$feature-active');
    final validPassword = TestDataFactory.validPassword('$feature-valid');
    final invalidPassword = TestDataFactory.invalidPassword('$feature-invalid');
    final longEmail = 'qa_${''.padRight(58, 'a')}@example.test';
    final longPassword = '${TestDataFactory.validPassword('$feature-long')}Z9!';

    return [
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify successful login with valid credentials',
        type: 'POSITIVE',
        priority: 'High',
        preconditions: [
          'The login page is reachable in a supported browser.',
          'An active test account exists for $validEmail.',
        ],
        steps: [
          _step(
            'Navigate to the login page',
            'https://auth.example.test/login',
            'The page displays email and password fields, a visible sign in button, and no pre-filled credentials.',
          ),
          _step(
            'Enter valid credentials into the login form',
            '$validEmail / $validPassword',
            'The fields accept the values and the sign in button remains available.',
          ),
          _step(
            'Click the sign in button',
            '',
            'The application redirects to the authenticated landing page and displays the active account state.',
          ),
        ],
        expectedResult:
            'The user is authenticated with the valid account, redirected to the protected landing page, and an active browser session is created for $validEmail.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify login failure with incorrect password',
        type: 'NEGATIVE',
        priority: 'High',
        preconditions: [
          'The login page is open.',
          'A registered test account exists for $lockedEmail.',
        ],
        steps: [
          _step(
            'Enter a registered email address',
            lockedEmail,
            'The email field accepts the address and shows no format validation error.',
          ),
          _step(
            'Enter an incorrect password',
            invalidPassword,
            'The password field masks the entered value and keeps the form available for submission.',
          ),
          _step(
            'Click the sign in button',
            '',
            'A specific authentication error appears and the page does not redirect to a protected area.',
          ),
        ],
        expectedResult:
            'The application rejects the incorrect password, keeps the user unauthenticated, preserves the entered email address, and displays a clear field-level error.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify required validation when email is missing',
        type: 'VALIDATION',
        priority: 'High',
        preconditions: ['The login page is open with empty fields.'],
        steps: [
          _step(
            'Leave the email field empty',
            '',
            'The email field remains blank and no hidden value is inserted.',
          ),
          _step(
            'Enter a valid password',
            validPassword,
            'The password field accepts the value while the email field remains required.',
          ),
          _step(
            'Click the sign in button',
            '',
            'The form stays on the login page and displays an email required message near the email field.',
          ),
        ],
        expectedResult:
            'Submission is blocked until the email field is populated, the password value remains available for correction, and no authenticated session is created.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify required validation when password is missing',
        type: 'VALIDATION',
        priority: 'High',
        preconditions: ['The login page is open with empty fields.'],
        steps: [
          _step(
            'Enter a registered email address',
            validEmail,
            'The email field accepts the address and clears any previous email validation message.',
          ),
          _step(
            'Leave the password field empty',
            '',
            'The password field remains blank and the form identifies it as required.',
          ),
          _step(
            'Click the sign in button',
            '',
            'A password required message appears and the user remains on the login page.',
          ),
        ],
        expectedResult:
            'The login form blocks submission without a password, keeps the entered email visible, and does not create an authenticated browser session.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify email format validation rejects invalid addresses',
        type: 'VALIDATION',
        priority: 'Medium',
        preconditions: ['The login page is open.'],
        steps: [
          _step(
            'Enter an invalid email value',
            TestDataFactory.invalidEmail('$feature-email'),
            'The email field accepts the typed characters and marks the value as invalid.',
          ),
          _step(
            'Enter a valid password',
            validPassword,
            'The password field accepts the value without clearing the invalid email.',
          ),
          _step(
            'Click the sign in button',
            '',
            'The form displays an email format validation message and does not navigate away.',
          ),
        ],
        expectedResult:
            'The login form rejects the invalid email format before authentication, keeps the user on the same page, and shows a correction message tied to the email field.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify email field handles maximum character length',
        type: 'EDGE',
        priority: 'Medium',
        preconditions: ['The login page is open on a desktop browser.'],
        steps: [
          _step(
            'Paste an email value longer than the configured limit',
            longEmail,
            'The field either trims the value to the allowed length or displays a visible length validation message.',
          ),
          _step(
            'Enter a valid password',
            validPassword,
            'The password field accepts the value and the email validation state remains visible.',
          ),
          _step(
            'Click the sign in button',
            '',
            'The form prevents authentication while the email value violates the length rule.',
          ),
        ],
        expectedResult:
            'The email input enforces its maximum length without layout distortion, hidden truncation, or navigation to a protected page.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify password field enforces maximum character length',
        type: 'EDGE',
        priority: 'Medium',
        preconditions: ['The login page is open.'],
        steps: [
          _step(
            'Enter a registered email address',
            activeEmail,
            'The email field accepts the address without validation warnings.',
          ),
          _step(
            'Paste a password value beyond the allowed length',
            '$longPassword$longPassword$longPassword',
            'The password field enforces the configured limit and keeps the value masked.',
          ),
          _step(
            'Click the sign in button',
            '',
            'The form shows a password length validation message or rejects the submission without creating a session.',
          ),
        ],
        expectedResult:
            'The password input handles over-length values securely, keeps masking enabled, and prevents authentication with data outside the allowed boundary.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify login form handles SQL injection text safely',
        type: 'SECURITY',
        priority: 'High',
        preconditions: ['The login page is open in a clean browser session.'],
        steps: [
          _step(
            'Enter a SQL injection string in the email field',
            TestDataFactory.sqlInjection(),
            'The value remains visible as plain text and no debug or database error appears.',
          ),
          _step(
            'Enter any non-empty password value',
            invalidPassword,
            'The password field accepts the value and keeps it masked.',
          ),
          _step(
            'Click the sign in button',
            '',
            'The login attempt is rejected with a normal validation or authentication message.',
          ),
        ],
        expectedResult:
            'The application treats the SQL injection text as user input, creates no authenticated session, and exposes no query, stack trace, or internal system detail.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify login form handles script text safely',
        type: 'SECURITY',
        priority: 'High',
        preconditions: ['The login page is open.'],
        steps: [
          _step(
            'Enter script text in the email field',
            TestDataFactory.xssPayload(),
            'The script text is rendered as plain text in the input and no alert or script behavior runs.',
          ),
          _step(
            'Enter a valid password',
            validPassword,
            'The password field accepts the value without changing the email text.',
          ),
          _step(
            'Click the sign in button',
            '',
            'The form rejects the invalid email and keeps the user on the login page.',
          ),
        ],
        expectedResult:
            'Unsafe script text is not executed, the invalid email is rejected, and no protected page or sensitive browser state is exposed.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify logout invalidates the active session',
        type: 'SESSION',
        priority: 'High',
        preconditions: [
          'The user is signed in as $validEmail.',
          'The authenticated landing page is open.',
        ],
        steps: [
          _step(
            'Click the logout control',
            '',
            'The application redirects to the login page and removes the active session indicator.',
          ),
          _step(
            'Navigate directly to a protected page',
            'https://auth.example.test/dashboard',
            'The browser is redirected back to the login page.',
          ),
          _step(
            'Refresh the redirected login page',
            '',
            'The page remains unauthenticated and does not restore the previous protected view.',
          ),
        ],
        expectedResult:
            'After logout, protected pages remain inaccessible through direct navigation or refresh, and the previous authenticated session is not restored.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify session persists after page refresh',
        type: 'SESSION',
        priority: 'High',
        preconditions: [
          'The user is signed in as $activeEmail.',
          'The authenticated landing page is open.',
        ],
        steps: [
          _step(
            'Refresh the authenticated page',
            '',
            'The page reloads without showing the login form.',
          ),
          _step(
            'Inspect the visible account indicator',
            activeEmail,
            'The same account remains shown after the refresh completes.',
          ),
          _step(
            'Navigate to another protected page',
            'https://auth.example.test/account',
            'The protected page opens without requiring a new login.',
          ),
        ],
        expectedResult:
            'The authenticated session survives a normal browser refresh and continues to authorize protected navigation for the same account.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify session expires after inactivity timeout',
        type: 'SESSION',
        priority: 'High',
        preconditions: [
          'The user is signed in as $activeEmail.',
          'The configured inactivity timeout is available in the test environment.',
        ],
        steps: [
          _step(
            'Leave the authenticated page idle until the timeout period passes',
            'Timeout window configured for QA environment',
            'The page displays a session expired message or redirects to the login page.',
          ),
          _step(
            'Attempt to use a protected navigation link',
            'Account settings',
            'The application blocks the action and keeps the user unauthenticated.',
          ),
          _step(
            'Enter valid credentials again',
            '$activeEmail / $validPassword',
            'The login page accepts the credentials for a new authentication attempt.',
          ),
        ],
        expectedResult:
            'After inactivity timeout, the old session is cleared, protected actions require re-authentication, and a new login can start from the login page.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify concurrent sessions do not leak account data',
        type: 'SESSION',
        priority: 'High',
        preconditions: [
          'Two separate browser profiles are available.',
          'Two different QA accounts exist.',
        ],
        steps: [
          _step(
            'Sign in on browser profile A',
            '$activeEmail / $validPassword',
            'Profile A displays the account indicator for $activeEmail.',
          ),
          _step(
            'Sign in on browser profile B with a different account',
            '$lockedEmail / ${TestDataFactory.validPassword('$feature-second')}',
            'Profile B displays its own account indicator and does not show Profile A data.',
          ),
          _step(
            'Refresh both browser profiles',
            '',
            'Each profile keeps only its own authenticated account state.',
          ),
        ],
        expectedResult:
            'Separate browser sessions remain isolated, and account identifiers, dashboards, and session state do not cross between concurrent logins.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify keyboard navigation follows logical order',
        type: 'USABILITY',
        priority: 'Medium',
        preconditions: [
          'The login page is open and no pointer device is used.',
        ],
        steps: [
          _step(
            'Press Tab from the browser address area into the page',
            '',
            'Focus lands on the first interactive login control in visual order.',
          ),
          _step(
            'Continue pressing Tab through the login form',
            '',
            'Focus moves through email, password, password visibility control, sign in, and secondary links without skipping controls.',
          ),
          _step(
            'Press Enter on the sign in button after entering credentials',
            '$validEmail / $validPassword',
            'The form submits using the keyboard and provides the same result as clicking the button.',
          ),
        ],
        expectedResult:
            'The login workflow can be completed with keyboard navigation only, with visible focus indicators and no unreachable controls.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify repeated failed logins trigger account protection',
        type: 'SECURITY',
        priority: 'High',
        preconditions: [
          'The login page is open.',
          'Account protection threshold is configured in the QA environment.',
        ],
        steps: [
          _step(
            'Submit an incorrect password repeatedly',
            '$lockedEmail / $invalidPassword repeated until threshold',
            'Each failed attempt displays a normal authentication error without revealing whether the account exists.',
          ),
          _step(
            'Submit another incorrect password after the threshold',
            '$lockedEmail / ${invalidPassword}2',
            'The form displays an account protection or cooldown message.',
          ),
          _step(
            'Attempt login with the valid password during cooldown',
            '$lockedEmail / $validPassword',
            'The application blocks the attempt until the protection window ends or requires the configured recovery action.',
          ),
        ],
        expectedResult:
            'Repeated failed login attempts trigger account protection, prevent brute-force retries, and do not expose sensitive account existence details.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title:
            'Verify browser back button does not reopen protected page after logout',
        type: 'SECURITY',
        priority: 'High',
        preconditions: [
          'The user is signed in and then logs out from a protected page.',
        ],
        steps: [
          _step(
            'Click the browser Back button after logout',
            '',
            'The browser does not display usable protected content from the previous session.',
          ),
          _step(
            'Refresh the page reached by the Back button',
            '',
            'The application redirects to the login page or keeps protected content unavailable.',
          ),
          _step(
            'Navigate directly to the protected URL again',
            'https://auth.example.test/dashboard',
            'The application requires a fresh login before showing protected data.',
          ),
        ],
        expectedResult:
            'Protected content cannot be recovered from browser history after logout, and direct navigation still requires re-authentication.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify login trims leading and trailing email spaces',
        type: 'VALIDATION',
        priority: 'Medium',
        preconditions: ['The login page is open.'],
        steps: [
          _step(
            'Enter a registered email with leading and trailing spaces',
            '  $validEmail  ',
            'The email field either trims the spaces or shows a validation state that makes the spacing issue clear.',
          ),
          _step(
            'Enter the valid password',
            validPassword,
            'The password field accepts the value and remains masked.',
          ),
          _step(
            'Click the sign in button',
            '',
            'The application authenticates the trimmed email or displays a clear validation message without creating a duplicate account identity.',
          ),
        ],
        expectedResult:
            'Email whitespace is handled consistently, authentication does not create a separate spaced identity, and the tester can observe whether trimming or validation is applied.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title:
            'Verify password visibility toggle does not expose password after navigation',
        type: 'SECURITY',
        priority: 'Medium',
        preconditions: [
          'The login page includes a password visibility control.',
        ],
        steps: [
          _step(
            'Enter a valid password and turn visibility on',
            validPassword,
            'The password is temporarily visible only in the password field.',
          ),
          _step(
            'Navigate away from the login page and return',
            'https://auth.example.test/help then login page',
            'The password field is cleared or masked according to the security requirement.',
          ),
          _step(
            'Inspect the password field state',
            '',
            'The password is not left exposed in visible text after navigation.',
          ),
        ],
        expectedResult:
            'The password visibility control never leaves sensitive data exposed after navigation, refresh, or returning to the login page.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify login error message is accessible to screen readers',
        type: 'USABILITY',
        priority: 'Medium',
        preconditions: [
          'A screen reader or accessibility inspector is available.',
          'The login page is open.',
        ],
        steps: [
          _step(
            'Submit invalid credentials',
            '$lockedEmail / $invalidPassword',
            'The visible authentication error appears near the affected field.',
          ),
          _step(
            'Move screen reader focus to the error area',
            '',
            'The error text is announced with the affected field context.',
          ),
          _step(
            'Correct the password field',
            validPassword,
            'The error state clears when valid input is provided for a new attempt.',
          ),
        ],
        expectedResult:
            'Authentication errors are visible and announced through accessibility tooling, allowing keyboard and screen-reader users to understand and correct the failure.',
      ),
    ];
  }

  static List<TestCaseModel> _authApiCases(
    String module,
    String feature,
    String platform,
  ) {
    final email = TestDataFactory.validEmail('$feature-api');
    final password = TestDataFactory.validPassword('$feature-api');
    final endpoint =
        '/${feature.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
    return [
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify login endpoint returns success for valid credentials',
        type: 'POSITIVE',
        priority: 'High',
        preconditions: ['The authentication API is reachable.'],
        steps: [
          _step(
            'Send a POST request to $endpoint',
            '{"email":"$email","password":"$password"}',
            'The service returns a successful authentication status.',
          ),
          _step(
            'Validate the response body',
            '',
            'The response includes the documented session identifier and account reference fields.',
          ),
          _step(
            'Use the returned session on a protected endpoint',
            '/account/profile',
            'The protected endpoint returns data for $email.',
          ),
        ],
        expectedResult:
            'Valid API credentials create an authenticated session response that can access protected endpoints using the documented contract.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify login endpoint rejects invalid password',
        type: 'NEGATIVE',
        priority: 'High',
        preconditions: ['A registered API test account exists for $email.'],
        steps: [
          _step(
            'Send a POST request to $endpoint',
            '{"email":"$email","password":"${TestDataFactory.invalidPassword('$feature-api')}"}',
            'The service returns an authentication failure status.',
          ),
          _step(
            'Inspect the error body',
            '',
            'The body contains a documented error code without stack traces or account enumeration details.',
          ),
          _step(
            'Call a protected endpoint without a valid session',
            '/account/profile',
            'The service rejects the request as unauthenticated.',
          ),
        ],
        expectedResult:
            'The API rejects the invalid password, exposes only the documented error response, and does not issue a usable session.',
      ),
    ];
  }

  static List<TestCaseModel> _authMobileCases(
    String module,
    String feature,
    String platform,
  ) {
    final email = TestDataFactory.validEmail('$feature-mobile');
    final password = TestDataFactory.validPassword('$feature-mobile');
    return [
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify successful mobile login with valid credentials',
        type: 'POSITIVE',
        priority: 'High',
        preconditions: ['The app is installed and the login screen is open.'],
        steps: [
          _step(
            'Tap the email field',
            email,
            'The keyboard appears and the field accepts the email address.',
          ),
          _step(
            'Tap the password field',
            password,
            'The password is entered in masked form.',
          ),
          _step(
            'Tap the sign in button',
            '',
            'The app opens the authenticated home screen and displays the signed-in account.',
          ),
        ],
        expectedResult:
            'The mobile app authenticates the valid user and opens the protected home screen without exposing the password.',
      ),
    ];
  }

  static List<TestCaseModel> _genericCases(
    String module,
    String feature,
    String platform,
  ) {
    final email = TestDataFactory.validEmail('$feature-generic');
    final reference = TestDataFactory.reference(feature);
    return [
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify $feature completes with valid required data',
        type: 'POSITIVE',
        priority: 'High',
        preconditions: [
          'The $feature interface is available in the QA environment.',
        ],
        steps: [
          _step(
            'Open the $feature interface',
            '',
            'The primary fields and action control are visible.',
          ),
          _step(
            'Enter valid required data',
            '$email / $reference',
            'The fields accept the data and show no validation errors.',
          ),
          _step(
            'Submit the $feature form',
            '',
            'The interface displays the completed state and a traceable confirmation reference.',
          ),
        ],
        expectedResult:
            'The $feature workflow accepts valid data, persists the intended change, and displays a confirmation state that can be verified by the tester.',
      ),
      _case(
        module: module,
        feature: feature,
        platform: platform,
        title: 'Verify $feature blocks missing required data',
        type: 'VALIDATION',
        priority: 'High',
        preconditions: ['The $feature interface is open with no data entered.'],
        steps: [
          _step(
            'Leave all required fields empty',
            '',
            'Required fields remain blank and are available for validation.',
          ),
          _step(
            'Submit the $feature form',
            '',
            'The interface prevents submission and highlights each missing required field.',
          ),
          _step(
            'Enter valid data into one required field',
            email,
            'The corrected field clears its validation state while other missing fields remain highlighted.',
          ),
        ],
        expectedResult:
            'The $feature workflow blocks incomplete submissions, keeps entered corrections, and displays field-level validation messages.',
      ),
    ];
  }

  static TestCaseModel _variantCase({
    required String module,
    required String feature,
    required String platform,
    required int variant,
  }) {
    final reference = TestDataFactory.reference('$feature-$variant');
    return _case(
      module: module,
      feature: feature,
      platform: platform,
      title:
          'Verify $feature preserves user input during retry flow - Variant $variant',
      type: 'NETWORK',
      priority: 'Medium',
      preconditions: [
        'The $feature interface is open and the QA environment can simulate a temporary network interruption.',
      ],
      steps: [
        _step(
          platform == 'Mobile'
              ? 'Enter required data and disable network connectivity'
              : platform == 'API'
              ? 'Send a request while the service dependency is unavailable'
              : 'Enter required data and simulate a temporary network interruption',
          reference,
          'The workflow displays a visible retry or unavailable state without losing the entered data.',
        ),
        _step(
          platform == 'API'
              ? 'Restore the dependency and resend the request'
              : 'Restore connectivity and use the retry action',
          '',
          'The workflow attempts the operation again with the same submitted data.',
        ),
        _step(
          'Verify the final state after retry',
          '',
          'The workflow reaches either a confirmed completion state or a clear validation state without duplicate submissions.',
        ),
      ],
      expectedResult:
          'The $feature workflow preserves user-entered data during retry, avoids duplicate processing, and gives the tester a clear final state.',
    );
  }

  static TestCaseModel _case({
    required String module,
    required String feature,
    required String platform,
    required String title,
    required String type,
    required String priority,
    required List<String> preconditions,
    required List<TestStep> steps,
    required String expectedResult,
  }) {
    return TestCaseModel(
      source: CaseSource.fallback,
      title: title,
      module: module,
      feature: feature,
      platform: platform,
      priority: priority,
      type: type,
      preconditions: preconditions,
      steps: steps,
      expectedResult: expectedResult,
      actualResult: '',
      status: 'Not Executed',
    );
  }

  static TestStep _step(String action, String data, String expected) {
    return TestStep(action: action, data: data, expected: expected);
  }
}
