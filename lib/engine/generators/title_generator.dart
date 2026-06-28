import '../models/scenario.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';

class TitleGenerator {
  static String generate(Scenario scenario) {
    final action = scenario.action;
    final entity = scenario.entity;
    final entityName = entity.displayName;
    final actionName = action.displayName;
    final capAction = actionName[0].toUpperCase() + actionName.substring(1);
    final capEntity = entityName[0].toUpperCase() + entityName.substring(1);

    if (scenario.category == 'positive') {
      return _positiveTitle(action, entityName, capAction, capEntity, actionName);
    } else if (scenario.category == 'negative') {
      return _negativeTitle(action, entityName, capAction, capEntity, actionName);
    } else if (scenario.category == 'validation') {
      if (scenario.condition != 'valid' && scenario.condition.isNotEmpty) {
        return _validationTitleForCondition(scenario.condition, action, entityName, actionName);
      }
      return _validationTitle(action, entityName, actionName);
    } else if (scenario.category == 'security') {
      if (scenario.condition != 'valid' && scenario.condition.isNotEmpty) {
        return _securityTitleForCondition(scenario.condition, action, entityName, actionName);
      }
      return _securityTitle(action, entityName, actionName);
    } else if (scenario.category == 'boundary') {
      if (scenario.condition != 'valid' && scenario.condition.isNotEmpty) {
        return _boundaryTitleForCondition(scenario.condition, action, entityName, actionName);
      }
      return _boundaryTitle(action, entityName, capAction, capEntity, actionName);
    } else if (scenario.category == 'session') {
      if (scenario.condition != 'valid' && scenario.condition.isNotEmpty) {
        return _sessionTitleForCondition(scenario.condition, action, entityName, actionName);
      }
      return _sessionTitle(action, entityName, capAction, capEntity, actionName);
    }
    return '${capAction} ${capEntity}';
  }

  static String _positiveTitle(ActionType action, String entity, String capAction, String capEntity, String actionName) {
    switch (action) {
      case ActionType.login:
        return 'Login with valid credentials';
      case ActionType.logout:
        return 'Successful logout';
      case ActionType.authenticate:
        return 'Authentication with valid credentials';
      case ActionType.create:
        return 'Create $entity with required fields';
      case ActionType.update:
        return 'Update $entity fields';
      case ActionType.delete:
        return 'Delete $entity after confirmation';
      case ActionType.view:
        return 'View $entity details';
      case ActionType.refresh:
        return 'Session token refresh';
      case ActionType.reset:
        return 'Password reset with valid token';
      case ActionType.verify:
        return 'OTP verification with valid code';
      case ActionType.authorize:
        return 'OAuth authorization grants access';
      case ActionType.add:
        return 'Add $entity to cart';
      case ActionType.remove:
        return 'Remove $entity from cart';
      case ActionType.checkout:
        return 'Checkout with valid payment';
      case ActionType.pay:
        return 'Payment with valid method';
      case ActionType.confirm:
        return 'Confirm $entity';
      case ActionType.cancel:
        return 'Cancel $entity';
      case ActionType.reschedule:
        return 'Reschedule $entity';
      case ActionType.book:
        return 'Book $entity';
      case ActionType.transfer:
        return 'Transfer to valid beneficiary';
      case ActionType.deposit:
        return 'Deposit to account';
      case ActionType.withdraw:
        return 'Withdrawal from account';
      case ActionType.send:
        return 'API call with valid payload';
      case ActionType.trigger:
        return 'Webhook event triggers';
      case ActionType.share:
        return 'Share $entity with recipients';
      default:
        return '$capAction $capEntity';
    }
  }

  static String _negativeTitle(ActionType action, String entity, String capAction, String capEntity, String actionName) {
    switch (action) {
      case ActionType.login:
        return 'Login with invalid credentials';
      case ActionType.authenticate:
        return 'Authentication with invalid credentials';
      case ActionType.create:
        return 'Creating $entity with missing fields fails';
      case ActionType.update:
        return 'Update $entity with invalid data';
      case ActionType.delete:
        return 'Delete non-existent $entity';
      case ActionType.pay:
        return 'Payment with expired card';
      case ActionType.apply:
        return 'Applying expired coupon';
      case ActionType.transfer:
        return 'Transfer with insufficient funds';
      case ActionType.reschedule:
        return 'Reschedule to unavailable slot';
      case ActionType.book:
        return 'Booking occupied slot';
      case ActionType.verify:
        return 'Verification with expired OTP';
      case ActionType.send:
        return 'API request with invalid payload';
      case ActionType.trigger:
        return 'Webhook with invalid signature';
      default:
        return '$capAction $capEntity — $entity $actionName fails';
    }
  }

  static String _validationTitle(ActionType action, String entity, String actionName) {
    switch (action) {
      case ActionType.create:
        return 'Input validation — creating $entity with special characters and long input limits';
      case ActionType.update:
        return 'Input validation — updating $entity with out-of-range values and invalid formats';
      case ActionType.login:
        return 'Input validation — login form rejects malformed email and short passwords';
      default:
        return 'Validate $entity input constraints during $actionName';
    }
  }

  static String _validationTitleForCondition(String condition, ActionType action, String entity, String actionName) {
    switch (condition) {
      case 'special_chars':
        return 'Validation: $entity $actionName with special characters and symbols is rejected';
      case 'unusual':
        return 'Validation: $entity $actionName with unusual Unicode input is normalized';
      case 'extremely_long':
        return 'Validation: $entity $actionName with extremely long input truncates correctly';
      case 'invalid_format':
        return 'Validation: $entity $actionName with invalid format (email/phone/date) is rejected';
      case 'empty':
        return 'Validation: $entity $actionName with empty required fields shows validation errors';
      default:
        return 'Validation: $entity $actionName with $condition input is validated correctly';
    }
  }

  static String _securityTitle(ActionType action, String entity, String actionName) {
    switch (action) {
      case ActionType.login:
        return 'Security: malicious login attempt with SQL injection payload is rejected';
      case ActionType.authenticate:
        return 'Security: malicious authentication payload is sanitized and blocked';
      case ActionType.send:
        return 'Security: API call with missing or expired API key returns 401 Unauthorized';
      default:
        return 'Security: $entity $actionName with malicious input is sanitized and rejected';
    }
  }

  static String _securityTitleForCondition(String condition, ActionType action, String entity, String actionName) {
    switch (condition) {
      case 'sql_injection':
        return 'Security: $entity $actionName with SQL injection payload is rejected';
      case 'xss':
        return 'Security: $entity $actionName with XSS payload is sanitized and rejected';
      case 'bruteforce':
        return 'Security: repeated $entity $actionName with invalid credentials triggers account lockout';
      case 'jwt_hijack':
        return 'Security: $entity $actionName with forged JWT token returns 401 Unauthorized';
      case 'masquerade':
        return 'Security: $entity $actionName with masqueraded identity is blocked';
      default:
        return 'Security: $entity $actionName with malicious $condition payload is sanitized and rejected';
    }
  }

  static String _boundaryTitle(ActionType action, String entity, String capAction, String capEntity, String actionName) {
    switch (action) {
      case ActionType.create:
        return 'Boundary test: creating $entity with maximum allowed field lengths and values';
      case ActionType.pay:
        return 'Boundary test: payment with minimum and maximum allowed amounts';
      case ActionType.transfer:
        return 'Boundary test: transfer at daily limit boundary and just above limit';
      default:
        return 'Boundary test: $entity $actionName at maximum allowed values';
    }
  }

  static String _boundaryTitleForCondition(String condition, ActionType action, String entity, String actionName) {
    switch (condition) {
      case 'empty':
        return 'Boundary test: $entity $actionName with empty values is handled';
      case 'max_length':
        return 'Boundary test: $entity $actionName with maximum allowed input length';
      case 'min_value':
        return 'Boundary test: $entity $actionName with minimum allowed value (0 or negative)';
      case 'max_value':
        return 'Boundary test: $entity $actionName with maximum allowed value (overflow boundary)';
      case 'exceed':
        return 'Boundary test: $entity $actionName with values exceeding limits is rejected';
      default:
        return 'Boundary test: $entity $actionName at $condition boundary';
    }
  }

  static String _sessionTitle(ActionType action, String entity, String capAction, String capEntity, String actionName) {
    switch (action) {
      case ActionType.login:
        return 'Session: $entity $actionName after session expiry is blocked';
      case ActionType.refresh:
        return 'Session: token refresh with expired refresh token fails after session expiry';
      default:
        return 'Session expired: $entity $actionName after session timeout redirects to login';
    }
  }

  static String _sessionTitleForCondition(String condition, ActionType action, String entity, String actionName) {
    switch (condition) {
      case 'expired':
        return 'Session: $entity $actionName with expired session token is blocked';
      case 'revoked':
        return 'Session: $entity $actionName with revoked token returns 403 Forbidden';
      case 'stale':
        return 'Session: $entity $actionName with stale refresh token triggers re-login';
      case 'invalid':
        return 'Session: $entity $actionName with tampered session cookie is rejected';
      default:
        return 'Session: $entity $actionName under $condition session condition is handled';
    }
  }
}
