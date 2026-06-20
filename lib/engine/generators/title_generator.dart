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
    return '${capAction} ${capEntity} — $feature';
  }

  static String _positiveTitle(ActionType action, String entity, String capAction, String capEntity, String actionName, String feature) {
    switch (action) {
      case ActionType.login:
        return 'Login with valid credentials — $feature';
      case ActionType.logout:
        return 'Successful logout — $feature';
      case ActionType.authenticate:
        return 'Authentication with valid credentials — $feature';
      case ActionType.create:
        return 'Create $entity with required fields — $feature';
      case ActionType.update:
        return 'Update $entity fields — $feature';
      case ActionType.delete:
        return 'Delete $entity after confirmation — $feature';
      case ActionType.view:
        return 'View $entity details — $feature';
      case ActionType.refresh:
        return 'Session token refresh — $feature';
      case ActionType.reset:
        return 'Password reset with valid token — $feature';
      case ActionType.verify:
        return 'OTP verification with valid code — $feature';
      case ActionType.authorize:
        return 'OAuth authorization grants access — $feature';
      case ActionType.add:
        return 'Add $entity to cart — $feature';
      case ActionType.remove:
        return 'Remove $entity from cart — $feature';
      case ActionType.checkout:
        return 'Checkout with valid payment — $feature';
      case ActionType.pay:
        return 'Payment with valid method — $feature';
      case ActionType.confirm:
        return 'Confirm $entity — $feature';
      case ActionType.cancel:
        return 'Cancel $entity — $feature';
      case ActionType.reschedule:
        return 'Reschedule $entity — $feature';
      case ActionType.book:
        return 'Book $entity — $feature';
      case ActionType.transfer:
        return 'Transfer to valid beneficiary — $feature';
      case ActionType.deposit:
        return 'Deposit to account — $feature';
      case ActionType.withdraw:
        return 'Withdrawal from account — $feature';
      case ActionType.send:
        return 'API call with valid payload — $feature';
      case ActionType.trigger:
        return 'Webhook event triggers — $feature';
      case ActionType.share:
        return 'Share $entity with recipients — $feature';
      default:
        return '$capAction $capEntity — $feature';
    }
  }

  static String _negativeTitle(ActionType action, String entity, String capAction, String capEntity, String actionName, String feature) {
    switch (action) {
      case ActionType.login:
        return 'Login with invalid credentials — $feature';
      case ActionType.authenticate:
        return 'Authentication with invalid credentials — $feature';
      case ActionType.create:
        return 'Creating $entity with missing fields fails — $feature';
      case ActionType.update:
        return 'Update $entity with invalid data — $feature';
      case ActionType.delete:
        return 'Delete non-existent $entity — $feature';
      case ActionType.pay:
        return 'Payment with expired card — $feature';
      case ActionType.apply:
        return 'Applying expired coupon — $feature';
      case ActionType.transfer:
        return 'Transfer with insufficient funds — $feature';
      case ActionType.reschedule:
        return 'Reschedule to unavailable slot — $feature';
      case ActionType.book:
        return 'Booking occupied slot — $feature';
      case ActionType.verify:
        return 'Verification with expired OTP — $feature';
      case ActionType.send:
        return 'API request with invalid payload — $feature';
      case ActionType.trigger:
        return 'Webhook with invalid signature — $feature';
      default:
        return '$capAction $capEntity — $entity $actionName fails — $feature';
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
