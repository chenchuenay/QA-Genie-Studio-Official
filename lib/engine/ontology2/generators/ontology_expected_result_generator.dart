import '../model/entity_def.dart';
import '../model/action_def.dart';

class OntologyExpectedResultGenerator {
  static String generate(
    String category,
    String condition,
    bool isPositive,
    EntityDef entity,
    ActionDef action,
    String platform,
  ) {
    if (isPositive) {
      return _positiveResult(action, entity, platform);
    } else {
      return _negativeResult(action, entity, platform);
    }
  }

  static String _positiveResult(ActionDef action, EntityDef entity, String platform) {
    switch (action.id) {
      case 'login':
        return 'User is redirected to the dashboard/home page. The top navigation shows the display name and avatar. A welcome message confirms successful login. The session cookie/token is set and accessible for subsequent API calls.';
      case 'logout':
        return 'User is redirected to the login page. Session data is cleared. The back button does not expose authenticated content. All protected routes redirect to the login page.';
      case 'authenticate':
        return 'Authentication succeeds. The API returns HTTP 200 with a valid JWT access token and refresh token. User profile data is returned in the response. The session is established and associated with the authenticated user.';
      case 'authorize':
        return 'OAuth authorization succeeds. The user is redirected to the application with an authorization code. The code is exchanged for access and refresh tokens. The requested scopes are granted.';
      case 'refresh':
        return 'Token refresh succeeds. A new access token is issued with extended expiration. The user remains authenticated without interruption to their current session.';
      case 'reset':
        return 'Password reset completes successfully. A confirmation message is displayed. The user can log in with the new password. The old password is invalidated.';
      case 'verify':
        return 'OTP/verification code is accepted. The user is granted access to the protected resource or action. The verification status is recorded.';
      default:
        return '${entity.displayName} operation completes successfully. The system performs the expected state transition and returns appropriate confirmation.';
    }
  }

  static String _negativeResult(ActionDef action, EntityDef entity, String platform) {
    switch (action.id) {
      case 'login':
        return 'The form displays a clear error message without revealing whether the email exists. The form does not submit. Fields retain their entered values for correction.';
      case 'authenticate':
        return 'Authentication fails. The API returns HTTP 401 with an error message. No session token is issued. The user remains on the login page.';
      case 'authorize':
        return 'OAuth authorization fails. The provider returns an error response. No authorization code is issued. The user is redirected back with an error parameter. The application handles the error gracefully.';
      case 'refresh':
        return 'Token refresh fails. The API returns HTTP 401. The user is redirected to re-authenticate.';
      case 'reset':
        return 'Password reset fails. An error message indicates the token is invalid or expired. The password remains unchanged.';
      case 'verify':
        return 'Verification fails. An error message indicates the code is invalid or expired. Access to the protected resource is denied.';
      default:
        return 'The operation is rejected with a clear error message. No system state changes occur. The user can correct the input and retry.';
    }
  }
}
