import '../models/scenario.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';

class TitleGenerator {
  static String generate(Scenario scenario, String feature) {
    final action = scenario.action;
    final entity = scenario.entity;
    final entityName = entity.displayName;
    final actionName = action.displayName;
    final capAction = actionName[0].toUpperCase() + actionName.substring(1);
    final capEntity = entityName[0].toUpperCase() + entityName.substring(1);

    if (scenario.category == 'positive') {
      return _positiveTitle(action, entityName, capAction, capEntity, actionName, feature);
    } else if (scenario.category == 'negative') {
      return _negativeTitle(action, entityName, capAction, capEntity, actionName, feature);
    } else if (scenario.category == 'validation') {
      if (scenario.condition != 'valid' && scenario.condition.isNotEmpty) {
        return _validationTitleForCondition(scenario.condition, action, entityName, actionName, feature);
      }
      return _validationTitle(action, entityName, actionName, feature);
    } else if (scenario.category == 'security') {
      if (scenario.condition != 'valid' && scenario.condition.isNotEmpty) {
        return _securityTitleForCondition(scenario.condition, action, entityName, actionName, feature);
      }
      return _securityTitle(action, entityName, actionName, feature);
    } else if (scenario.category == 'boundary') {
      if (scenario.condition != 'valid' && scenario.condition.isNotEmpty) {
        return _boundaryTitleForCondition(scenario.condition, action, entityName, actionName, feature);
      }
      return _boundaryTitle(action, entityName, capAction, capEntity, actionName, feature);
    } else if (scenario.category == 'session') {
      if (scenario.condition != 'valid' && scenario.condition.isNotEmpty) {
        return _sessionTitleForCondition(scenario.condition, action, entityName, actionName, feature);
      }
      return _sessionTitle(action, entityName, capAction, capEntity, actionName, feature);
    }
    return '${actionName} ${entityName} — $feature';
  }

  static String _positiveTitle(ActionType action, String entity, String capAction, String capEntity, String actionName, String feature) {
    switch (action) {
      case ActionType.login:
        return 'Verify user can successfully log in with valid email and password — $feature';
      case ActionType.logout:
        return 'User can log out successfully and session is terminated — $feature';
      case ActionType.authenticate:
        return 'User authenticates successfully with valid credentials and receives session token — $feature';
      case ActionType.create:
        return 'User can create a new $entity with all required fields and save it successfully — $feature';
      case ActionType.update:
        return 'User can update existing $entity fields and changes are persisted correctly — $feature';
      case ActionType.delete:
        return 'User can delete a $entity after confirmation and it is removed from the system — $feature';
      case ActionType.view:
        return 'User can view $entity details and all fields are displayed accurately — $feature';
      case ActionType.refresh:
        return 'Session token refresh returns a new valid token without requiring re-authentication — $feature';
      case ActionType.reset:
        return 'Password reset flow completes successfully and new credentials are accepted — $feature';
      case ActionType.verify:
        return 'OTP/token verification succeeds with valid code and grants access — $feature';
      case ActionType.authorize:
        return 'OAuth authorization grants access to requested resources successfully — $feature';
      case ActionType.add:
        return 'User can add a $entity to the cart and quantity updates correctly — $feature';
      case ActionType.remove:
        return 'User can remove a $entity from the cart and total updates accordingly — $feature';
      case ActionType.checkout:
        return 'Checkout flow completes with valid payment and generates order confirmation — $feature';
      case ActionType.pay:
        return 'Payment is processed successfully and receipt is generated — $feature';
      case ActionType.confirm:
        return 'User can confirm the $entity and system updates the status — $feature';
      case ActionType.cancel:
        return 'User can cancel the $entity and cancellation is reflected immediately — $feature';
      case ActionType.reschedule:
        return 'User can reschedule the $entity and updated time slot is confirmed — $feature';
      case ActionType.book:
        return 'User can book an available $entity slot and receives confirmation — $feature';
      case ActionType.transfer:
        return 'Funds transfer to a valid beneficiary completes and balances update correctly — $feature';
      case ActionType.deposit:
        return 'Deposit to the account is credited and balance reflects the new amount — $feature';
      case ActionType.withdraw:
        return 'Withdrawal from account with sufficient funds processes successfully — $feature';
      case ActionType.send:
        return 'API request with valid payload is sent and processed successfully — $feature';
      case ActionType.trigger:
        return 'Webhook event triggers successfully and callback is delivered — $feature';
      case ActionType.share:
        return 'User can share $entity with authorized recipients and access is granted — $feature';
      default:
        return '$capAction $capEntity — verify successful $actionName of $entity in $feature';
    }
  }

  static String _negativeTitle(ActionType action, String entity, String capAction, String capEntity, String actionName, String feature) {
    switch (action) {
      case ActionType.login:
        return 'Attempt to log in with invalid credentials should display error message — $feature';
      case ActionType.authenticate:
        return 'Authentication with invalid credentials returns appropriate error — $feature';
      case ActionType.create:
        return 'Creating $entity with missing required fields should show validation errors — $feature';
      case ActionType.update:
        return 'Updating $entity with invalid data should be rejected with error — $feature';
      case ActionType.delete:
        return 'Deleting a non-existent $entity should return not found error — $feature';
      case ActionType.pay:
        return 'Payment with expired card is rejected and user is prompted to use another method — $feature';
      case ActionType.apply:
        return 'Applying an expired or invalid coupon code shows rejection message — $feature';
      case ActionType.transfer:
        return 'Transfer attempt with insufficient funds should display insufficient balance error — $feature';
      case ActionType.reschedule:
        return 'Rescheduling to an unavailable time slot should show conflict error — $feature';
      case ActionType.book:
        return 'Booking an already occupied slot should display scheduling conflict error — $feature';
      case ActionType.verify:
        return 'Verification with expired or invalid OTP should fail with error message — $feature';
      case ActionType.send:
        return 'API request with invalid payload should be rejected with validation error — $feature';
      case ActionType.trigger:
        return 'Webhook trigger with invalid signature should be rejected with 401 — $feature';
      default:
        return '$capAction $capEntity — verify error handling when $entity $actionName fails';
    }
  }

  static String _validationTitle(ActionType action, String entity, String actionName, String feature) {
    switch (action) {
      case ActionType.create:
        return 'Input validation — creating $entity with special characters and long input limits in $feature';
      case ActionType.update:
        return 'Input validation — updating $entity with out-of-range values and invalid formats in $feature';
      case ActionType.login:
        return 'Input validation — login form rejects malformed email and short passwords in $feature';
      default:
        return '$feature — validate $entity input constraints during $actionName';
    }
  }

  static String _validationTitleForCondition(String condition, ActionType action, String entity, String actionName, String feature) {
    switch (condition) {
      case 'special_chars':
        return '$feature — validation: $entity $actionName with special characters and symbols is rejected';
      case 'unusual':
        return '$feature — validation: $entity $actionName with unusual Unicode input is normalized';
      case 'extremely_long':
        return '$feature — validation: $entity $actionName with extremely long input truncates correctly';
      case 'invalid_format':
        return '$feature — validation: $entity $actionName with invalid format (email/phone/date) is rejected';
      case 'empty':
        return '$feature — validation: $entity $actionName with empty required fields shows validation errors';
      default:
        return '$feature — validation: $entity $actionName with $condition input is validated correctly';
    }
  }

  static String _securityTitle(ActionType action, String entity, String actionName, String feature) {
    switch (action) {
      case ActionType.login:
        return '$feature — security: malicious login attempt with SQL injection payload is rejected';
      case ActionType.authenticate:
        return '$feature — security: malicious authentication payload is sanitized and blocked';
      case ActionType.send:
        return '$feature — security: API call with missing or expired API key returns 401 Unauthorized';
      default:
        return '$feature — security: $entity $actionName with malicious input is sanitized and rejected';
    }
  }

  static String _securityTitleForCondition(String condition, ActionType action, String entity, String actionName, String feature) {
    switch (condition) {
      case 'sql_injection':
        return '$feature — security: $entity $actionName with SQL injection payload is rejected';
      case 'xss':
        return '$feature — security: $entity $actionName with XSS payload is sanitized and rejected';
      case 'bruteforce':
        return '$feature — security: repeated $entity $actionName with invalid credentials triggers account lockout';
      case 'jwt_hijack':
        return '$feature — security: $entity $actionName with forged JWT token returns 401 Unauthorized';
      case 'masquerade':
        return '$feature — security: $entity $actionName with masqueraded identity is blocked';
      default:
        return '$feature — security: $entity $actionName with malicious $condition payload is sanitized and rejected';
    }
  }

  static String _boundaryTitle(ActionType action, String entity, String capAction, String capEntity, String actionName, String feature) {
    switch (action) {
      case ActionType.create:
        return '$feature — boundary test: creating $entity with maximum allowed field lengths and values';
      case ActionType.pay:
        return '$feature — boundary test: payment with minimum and maximum allowed amounts';
      case ActionType.transfer:
        return '$feature — boundary test: transfer at daily limit boundary and just above limit';
      default:
        return '$feature — boundary test: $entity $actionName at maximum allowed values';
    }
  }

  static String _boundaryTitleForCondition(String condition, ActionType action, String entity, String actionName, String feature) {
    switch (condition) {
      case 'empty':
        return '$feature — boundary test: $entity $actionName with empty values is handled';
      case 'max_length':
        return '$feature — boundary test: $entity $actionName with maximum allowed input length';
      case 'min_value':
        return '$feature — boundary test: $entity $actionName with minimum allowed value (0 or negative)';
      case 'max_value':
        return '$feature — boundary test: $entity $actionName with maximum allowed value (overflow boundary)';
      case 'exceed':
        return '$feature — boundary test: $entity $actionName with values exceeding limits is rejected';
      default:
        return '$feature — boundary test: $entity $actionName at $condition boundary';
    }
  }

  static String _sessionTitle(ActionType action, String entity, String capAction, String capEntity, String actionName, String feature) {
    switch (action) {
      case ActionType.login:
        return '$feature — session: $entity $actionName after session expiry is blocked';
      case ActionType.refresh:
        return '$feature — session: token refresh with expired refresh token fails after session expiry';
      default:
        return '$feature — session expired: $entity $actionName after session timeout redirects to login';
    }
  }

  static String _sessionTitleForCondition(String condition, ActionType action, String entity, String actionName, String feature) {
    switch (condition) {
      case 'expired':
        return '$feature — session: $entity $actionName with expired session token is blocked';
      case 'revoked':
        return '$feature — session: $entity $actionName with revoked token returns 403 Forbidden';
      case 'stale':
        return '$feature — session: $entity $actionName with stale refresh token triggers re-login';
      case 'invalid':
        return '$feature — session: $entity $actionName with tampered session cookie is rejected';
      default:
        return '$feature — session: $entity $actionName under $condition session condition is handled';
    }
  }
}
