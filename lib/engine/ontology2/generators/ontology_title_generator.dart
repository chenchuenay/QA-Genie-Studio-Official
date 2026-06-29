import '../model/entity_def.dart';
import '../model/action_def.dart';

class OntologyTitleGenerator {
  static String generate(String category, String condition, bool isPositive, EntityDef entity, ActionDef action) {
    final entityName = entity.displayName;
    final capEntity = entityName;
    final actionVerb = action.displayName;

    if (category == 'positive') {
      return _positive(action, entityName, actionVerb, entity.id);
    } else if (category == 'negative') {
      return _negative(action, entityName, actionVerb);
    } else if (category == 'validation') {
      return _validation(entityName, actionVerb, condition);
    } else if (category == 'security') {
      return _security(entityName, actionVerb, condition);
    } else if (category == 'boundary') {
      return _boundary(entityName, actionVerb, condition);
    } else if (category == 'session') {
      return _session(entityName, actionVerb, condition);
    }
    return '$actionVerb $capEntity';
  }

  static String _positive(ActionDef action, String entity, String verb, String entityId) {
    switch (action.id) {
      case 'login':
        return 'Login with valid credentials';
      case 'logout':
        return 'Successful logout from $entity';
      case 'authenticate':
        return 'Authentication with valid credentials';
      case 'authorize':
        return 'OAuth authorization grants access';
      case 'refresh':
        return 'Session token refresh succeeds';
      case 'reset':
        return 'Password reset with valid token';
      case 'verify':
        return 'OTP verification with valid code';
      case 'create':
        return 'Create $entity with required fields';
      case 'start':
        return 'Start $entity with valid configuration';
      case 'stop':
        return 'Stop $entity gracefully';
      case 'deploy':
        return 'Deploy $entity with valid configuration';
      case 'configure':
        return 'Configure $entity with valid settings';
      case 'train':
        return 'Train $entity with valid dataset';
      case 'predict':
        return 'Generate prediction using $entity';
      case 'send':
        return 'Send $entity with valid payload';
      case 'execute':
        return 'Execute $entity with valid parameters';
      case 'share':
        return 'Share $entity with recipients';
      case 'like':
        return 'Like $entity';
      case 'follow':
        return 'Follow $entity successfully';
      case 'calibrate':
        return 'Calibrate $entity with valid parameters';
      case 'diagnose':
        return 'Diagnose $entity for system health';
      case 'monitor':
        return 'Monitor $entity status';
      case 'backup':
        return 'Backup $entity data successfully';
      case 'restore':
        return 'Restore $entity from backup';
      case 'evaluate':
        return 'Evaluate $entity performance';
      case 'receive':
        return 'Receive $entity successfully';
      case 'transfer':
        return 'Transfer to valid $entity';
      case 'deposit':
        return 'Deposit to $entity';
      case 'withdraw':
        return 'Withdraw from $entity';
      case 'book':
        return 'Book $entity with valid details';
      case 'join':
        return 'Join $entity';
      case 'schedule':
        return 'Schedule $entity with valid details';
      case 'updateQuantity':
        return 'Update $entity quantity';
      default:
        return '$verb $entity successfully';
    }
  }

  static String _negative(ActionDef action, String entity, String verb) {
    switch (action.id) {
      case 'login':
        return 'Login with invalid credentials is rejected';
      case 'authenticate':
        return 'Authentication with invalid credentials fails';
      case 'authorize':
        return 'OAuth authorization with invalid provider fails';
      case 'refresh':
        return 'Token refresh with expired refresh token fails';
      case 'reset':
        return 'Password reset with invalid token fails';
      case 'verify':
        return 'OTP verification with invalid code fails';
      default:
        return '$verb $entity with invalid input fails';
    }
  }

  static String _validation(String entity, String verb, String condition) {
    switch (condition) {
      case 'empty':
        return 'Validation: $entity $verb with empty required fields shows errors';
      case 'invalid_format':
        return 'Validation: $entity $verb with invalid format is rejected';
      case 'max_length':
        return 'Validation: $entity $verb with exceeding character limit is truncated';
      case 'special_chars':
        return 'Validation: $entity $verb with special characters is sanitized';
      default:
        return 'Validation: $entity $verb with $condition input is validated';
    }
  }

  static String _security(String entity, String verb, String condition) {
    switch (condition) {
      case 'sql_injection':
        return 'Security: $entity $verb with SQL injection payload is rejected';
      case 'xss':
        return 'Security: $entity $verb with XSS payload is sanitized';
      case 'csrf_mismatch':
        return 'Security: $entity $verb with CSRF state mismatch is blocked';
      case 'oauth_replay':
        return 'Security: $entity $verb with replayed auth code is rejected';
      case 'bruteforce':
        return 'Security: repeated $entity $verb triggers account lockout';
      default:
        return 'Security: $entity $verb with malicious $condition input is rejected';
    }
  }

  static String _boundary(String entity, String verb, String condition) {
    switch (condition) {
      case 'maximum':
        return 'Boundary test: $entity $verb at maximum allowed value';
      case 'minimum':
        return 'Boundary test: $entity $verb at minimum allowed value';
      case 'max_redirect_uri':
        return 'Boundary test: $entity $verb with maximum redirect URI length';
      default:
        return 'Boundary test: $entity $verb at $condition boundary';
    }
  }

  static String _session(String entity, String verb, String condition) {
    switch (condition) {
      case 'expired':
        return 'Session: $entity $verb with expired session is blocked';
      case 'revoked':
        return 'Session: $entity $verb with revoked token is forbidden';
      case 'expired_code':
        return 'Session: $entity $verb with expired authorization code fails';
      default:
        return 'Session: $entity $verb under $condition session state';
    }
  }
}
