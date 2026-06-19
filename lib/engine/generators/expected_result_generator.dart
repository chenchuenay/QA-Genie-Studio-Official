import '../models/scenario.dart';
import '../ontology/states.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../models/domain_context.dart';

class ExpectedResultGenerator {
  static String generate(Scenario scenario, [DomainContext? domain, String platform = 'Web']) {
    if (domain == null) {
      return _legacyGenerate(scenario);
    }
    return _enhancedGenerate(scenario, domain, platform);
  }

  static String _legacyGenerate(Scenario scenario) {
    final outcome = _observableOutcome(scenario.targetState);
    if (scenario.isPositive) {
      return outcome.positive;
    } else {
      return outcome.negative;
    }
  }

  static String _enhancedGenerate(Scenario scenario, DomainContext domain, String platform) {
    final action = scenario.action;
    final entity = scenario.entity;

    if (scenario.isPositive) {
      return _positiveResult(action, entity, domain, platform, scenario.targetState);
    } else {
      return _negativeResult(action, entity, domain, platform, scenario.targetState);
    }
  }

  static _Outcome _observableOutcome(StateType state) {
    switch (state) {
      case StateType.authenticated:
        return _Outcome(
          'Dashboard is displayed',
          'Error message: Authentication failed',
        );
      case StateType.authorized:
        return _Outcome(
          'Protected content is visible',
          'Access denied message appears',
        );
      case StateType.active:
        return _Outcome('Operation completed', 'Operation failed, error shown');
      case StateType.completed:
        return _Outcome('Confirmation message appears', 'Transaction failed');
      case StateType.created:
        return _Outcome('New item is created', 'Creation failed');
      case StateType.updated:
        return _Outcome('Changes are saved', 'Update failed');
      case StateType.deleted:
        return _Outcome('Item is removed', 'Deletion failed');
      case StateType.scheduled:
        return _Outcome('Appointment confirmed', 'Scheduling failed');
      case StateType.redirected:
        return _Outcome('Page redirects', 'Redirect failed');
      default:
        return _Outcome('Success', 'Error');
    }
  }

  static String _positiveResult(ActionType action, EntityType entity, DomainContext domain, String platform, StateType targetState) {
    switch (action) {
      case ActionType.login:
        return 'User is redirected to the dashboard/home page. The top navigation shows the user\'s display name and avatar. A welcome message confirms successful login. The session cookie/token is set and accessible for subsequent API calls.';
      case ActionType.logout:
        return 'User is redirected to the login page. Session data is cleared from local storage. The back button does not expose authenticated content. All protected routes redirect to the login page.';
      case ActionType.authenticate:
        return 'Authentication succeeds. API returns HTTP 200 with a valid JWT access token and refresh token. User profile data is returned in the response. The session is established and associated with the authenticated user.';
      case ActionType.refresh:
        return 'Token refresh succeeds. A new access token is issued with an extended expiration time. The old token is invalidated. The user remains authenticated without interruption to their current session.';
      case ActionType.reset:
        return 'Password reset completes successfully. A confirmation message displays: "Your password has been reset successfully." The user can immediately log in with the new password. The old password is invalidated. A confirmation email is sent.';
      case ActionType.create:
        if (entity == EntityType.record) {
          return 'A new record is created successfully. The record appears in the records list with a unique Record ID. All entered fields are saved accurately. A confirmation toast displays: "Record created successfully." The user is redirected to the record detail view.';
        }
        if (entity == EntityType.appointment) {
          return 'Appointment is created successfully. The appointment appears in the schedule with status "Pending." A confirmation notification is sent. The provider\'s calendar is updated to reflect the new booking.';
        }
        return 'The $entity is created successfully. A confirmation with a unique identifier is displayed. The new $entity appears in the relevant list or view. All entered data is persisted correctly.';
      case ActionType.update:
        return 'The $entity is updated successfully. A success toast displays confirming the changes. The updated fields reflect the new values immediately in the UI. A timestamp of the last update is recorded.';
      case ActionType.delete:
        return 'The $entity is permanently deleted after confirmation. A success toast displays confirming the deletion. The $entity no longer appears in search results or lists. The deletion is logged in the audit trail.';
      case ActionType.view:
        return 'The $entity details are displayed with all fields populated accurately. Related data and attachments load without errors. The page renders within acceptable latency (< 2 seconds).';
      case ActionType.verify:
        return 'OTP/token verification succeeds. The user is granted access to the protected resource or action. The verification status is recorded. No session timeout occurs during the verification flow.';
      case ActionType.authorize:
        return 'OAuth authorization succeeds. The user is redirected to the application with an authorization code. The code is exchanged for access and refresh tokens. The requested scopes (email, profile) are granted.';
      case ActionType.add:
        return 'The item is added to the cart successfully. The cart badge count increments by the correct quantity. The cart drawer lists the item with correct name, quantity, and unit price. The subtotal updates correctly.';
      case ActionType.remove:
        return 'The item is removed from the cart. The cart badge count decreases accordingly. The cart total recalculates to reflect the removal. If the cart becomes empty, a "Your cart is empty" message displays.';
      case ActionType.checkout:
        return 'The checkout flow completes successfully. An order confirmation screen displays with the order number, item details, shipping address, and total. A confirmation email is sent to the registered email. The cart is cleared after successful order placement.';
      case ActionType.pay:
        return 'Payment is processed successfully. A receipt is generated with a unique transaction ID. The payment status shows as "Completed." The order status updates to "Paid." A confirmation notification is sent via email/push.';
      case ActionType.confirm:
        return 'The action is confirmed successfully. The status updates to reflect the confirmed state. All relevant parties receive a notification of the confirmation. The system transitions to the next logical state.';
      case ActionType.cancel:
        return 'The $entity is cancelled successfully. The status changes to "Cancelled" with a visual indicator. If applicable, the slot or resource is released back to availability. A cancellation confirmation is sent to the user.';
      case ActionType.reschedule:
        return 'The $entity is rescheduled successfully. The new date and time are confirmed and displayed. The previous time slot is released. All relevant parties receive updated scheduling notifications.';
      case ActionType.book:
        return 'The booking is confirmed. A confirmation displays the provider, date, time, and location/meeting link. The appointment appears in upcoming appointments with status "Confirmed." A notification/email is sent with the details.';
      case ActionType.transfer:
        return 'The transfer is executed successfully. A confirmation screen displays the transaction details including a unique transaction ID. The source account balance decreases by the transferred amount. The beneficiary account receives the funds. A transaction receipt is generated.';
      case ActionType.deposit:
        return 'The deposit is credited to the account. The account balance reflects the new amount. A transaction record appears in the account statement with the deposit details. A confirmation receipt is generated.';
      case ActionType.withdraw:
        return 'The withdrawal is processed successfully. The account balance decreases by the withdrawn amount. Cash/disbursement is issued if applicable. A transaction receipt with withdrawal details is generated.';
      case ActionType.send:
        return 'The API request is sent and processed successfully. The server responds with HTTP 200/201 and a valid response payload. The response contains the expected resource data. All response headers are valid.';
      case ActionType.trigger:
        return 'The webhook event is triggered successfully. The event payload is delivered to the configured callback URL. The webhook delivery log shows status "Delivered." The receiver acknowledges receipt with HTTP 200.';
      case ActionType.share:
        return 'The $entity is shared successfully with the authorized recipients. Access permissions are granted. The recipients receive a notification with access instructions. The sharing status is reflected in the $entity metadata.';
      default:
        return 'Operation completes successfully. The system performs the expected state transition and returns appropriate confirmation. All relevant UI elements update to reflect the new state.';
    }
  }

  static String _negativeResult(ActionType action, EntityType entity, DomainContext domain, String platform, StateType targetState) {
    switch (action) {
      case ActionType.login:
        return 'The form displays a clear error message: "Invalid email or password." No sensitive information about whether the email exists is revealed. The form does not submit. Fields retain their entered values for correction.';
      case ActionType.authenticate:
        return 'Authentication fails. The API returns HTTP 401 with an error message. No session token is issued. The user remains on the login page. Failed attempt count increments for brute force protection.';
      case ActionType.create:
        return 'Creation fails. The system returns a validation error identifying the invalid/missing fields. No partial data is saved. The form remains editable with entered values preserved. Specific error messages appear inline for each invalid field.';
      case ActionType.update:
        return 'Update fails. The system rejects the changes with an appropriate error message. The original data remains unchanged. No partial save occurs. The user can correct the input and retry.';
      case ActionType.delete:
        return 'Deletion fails. An error message explains why the $entity cannot be deleted (e.g., "Record has active dependencies"). The $entity remains accessible and unchanged. The system logs the failed attempt.';
      case ActionType.pay:
        return 'Payment is rejected. The payment gateway returns a decline code. The user sees a message: "Your card was declined. Please try a different payment method." No hold is placed. The order remains in unpaid state.';
      case ActionType.transfer:
        return 'The transfer is rejected before reaching the OTP step. An inline error displays: "Insufficient funds. Your available balance is \$X. Please enter a lower amount." No hold is placed on the account. No OTP is sent.';
      case ActionType.book:
        return 'The booking is rejected. An error message displays: "The selected time slot is not available. Please choose a different time or date." The original schedule remains unchanged. The slot does not become reserved.';
      case ActionType.reschedule:
        return 'The reschedule request is rejected with an error message indicating the target time slot is unavailable. The original appointment remains unchanged with its original date and time. The user can select a different slot.';
      case ActionType.trigger:
        return 'The webhook request is rejected with HTTP 401. The response body contains a signature mismatch error. No event processing occurs on the receiver side. The failed delivery is logged for monitoring.';
      case ActionType.send:
        return 'The API request is rejected. The server returns an appropriate 4xx status code with a clear error message identifying the invalid fields. No data mutation occurs on the server. The system state remains unchanged.';
      case ActionType.verify:
        return 'Verification fails. An error message displays: "Invalid or expired code. Please request a new code." Access to the protected resource is denied. The user can request a new OTP/token.';
      case ActionType.apply:
        return 'The coupon is rejected. An inline error message states the code is expired or invalid. The cart total remains unchanged. No discount is applied. The user can remove the code or try a different one.';
      default:
        return 'The operation is rejected with a clear error message. No system state changes occur. The user can correct the input and retry the operation. The error is logged for monitoring without exposing sensitive details.';
    }
  }
}

class _Outcome {
  final String positive;
  final String negative;
  _Outcome(this.positive, this.negative);
}
