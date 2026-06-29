import '../models/scenario.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../models/domain_context.dart';

class PreconditionGenerator {
  static List<String> generate(Scenario scenario, [DomainContext? domain]) {
    if (domain == null) {
      return _legacyGenerate(scenario);
    }
    return _enhancedGenerate(scenario, domain);
  }

  static List<String> _legacyGenerate(Scenario scenario) {
    final preconditions = <String>[];
    final entity = scenario.entity.displayName;
    preconditions.add('$entity exists');
    if (scenario.isPositive) {
      preconditions.add('$entity is ready for ${scenario.action.displayName}');
    } else {
      preconditions.add('$entity is in a state that prevents ${scenario.action.displayName}');
    }
    return preconditions;
  }

  static List<String> _enhancedGenerate(Scenario scenario, DomainContext domain) {
    final entity = scenario.entity;
    final action = scenario.action;
    final entityName = entity.displayName;

    final preconditions = <String>[
      _entitySpecificPrecondition(entity, action),
      _actionPrecondition(scenario, action, entityName),
      _domainPrerequisite(domain.id, action, entity),
    ];

    if (!scenario.isPositive) {
      preconditions.add(_negativePrerequisite(scenario, action, entityName));
    }

    if (action == ActionType.authorize) {
      preconditions.add('OAuth provider service is active and reachable (Google, Facebook, etc.)');
      preconditions.add('Registered OAuth client credentials (client_id, redirect_uri) are configured and verified');
      preconditions.add('Member is not currently authenticated via OAuth — fresh OAuth flow required');
    } else if (action == ActionType.login || action == ActionType.authenticate) {
      preconditions.add('Member account is active and verified (not locked, disabled, or pending)');
      preconditions.add('Login form is active and accepts input without pre-validation restrictions');
    } else if (action == ActionType.refresh) {
      preconditions.add('Current session token is active and verified with valid expiration window');
    } else if (action == ActionType.reset) {
      preconditions.add('Email delivery service is active and operational with verified send capability');
      preconditions.add('Registered member has active access to the verified email inbox');
    } else if (action == ActionType.pay || action == ActionType.checkout) {
      preconditions.add('Payment gateway is active and operational with verified test mode enabled');
      preconditions.add('Active cart contains at least one verified in-stock item with valid pricing');
    } else if (action == ActionType.transfer) {
      preconditions.add('Two-factor authentication is active and verified with registered OTP device');
      preconditions.add('Daily transaction limit is active and has not been reached for verified account');
    } else if (action == ActionType.book || action == ActionType.reschedule) {
      preconditions.add('Target time slot is active, within verified business hours, and not in the past');
    } else if (action == ActionType.trigger || action == ActionType.send) {
      preconditions.add('API endpoint is active and reachable with verified firewall allowing request');
    } else if (action == ActionType.create && entity == EntityType.record) {
      preconditions.add('Member has active "Create Record" permission with verified authorization');
      preconditions.add('Registered patient demographic data is available and verified for entry');
    } else if (action == ActionType.delete) {
      preconditions.add('$entityName is registered and eligible for deletion with no active dependencies');
    } else if (action == ActionType.view) {
      preconditions.add('View permission is active and verified for the requested resource');
    } else if (action == ActionType.create) {
      preconditions.add('Active creation form is available with all verified required fields');
    } else if (action == ActionType.cancel || action == ActionType.reschedule) {
      preconditions.add('Existing booking is active and verified with registered cancellation policy');
    }

    return preconditions;
  }

  static String _entitySpecificPrecondition(EntityType entity, ActionType action) {
    switch (entity) {
      case EntityType.account:
        return 'Registered member account is active and verified with valid credentials';
      case EntityType.credential:
        return 'Valid login credentials are available for the registered account';
      case EntityType.session:
        return 'Active session is authenticated and has not expired beyond the refresh window';
      case EntityType.order:
        return 'Registered order is active and ready for checkout with items in cart';
      case EntityType.cart:
        return 'Shopping cart is active and contains at least one in-stock item with pricing';
      case EntityType.item:
        return 'Product item is registered in inventory with active status and sufficient stock';
      case EntityType.payment:
        return 'Registered payment method is active and verified with sufficient available funds';
      case EntityType.coupon:
        return 'Valid discount coupon is active and registered with remaining usage available';
      case EntityType.beneficiary:
        return 'Beneficiary is verified and registered with active status approved for transfers';
      case EntityType.balance:
        return 'Source account balance is active and verified as sufficient for the transaction';
      case EntityType.accountTx:
        return 'Banking account is active and authenticated for transaction processing';
      case EntityType.appointment:
        return 'Available appointment slot is active within business hours for booking';
      case EntityType.provider:
        return 'Healthcare provider is active and registered with verified credentials';
      case EntityType.patient:
        return 'Patient is registered with active status and demographic data is available';
      case EntityType.record:
        return 'Medical record is active and accessible with verified authorization credentials';
      case EntityType.slot:
        return 'Target time slot is active and available within business hours';
      case EntityType.request:
        return 'Valid API request payload is prepared with authenticated session credentials';
      case EntityType.webhook:
        return 'Webhook endpoint is active and registered with verified secret key configured';
      case EntityType.event:
        return 'Triggered event is registered and active with payload matching expected schema';
      default:
        return 'Registered ${entity.displayName} is active and verified for the operation';
    }
  }

  static String _actionPrecondition(Scenario scenario, ActionType action, String entityName) {
    if (scenario.isPositive) {
      switch (action) {
        case ActionType.login:
          return 'Registered member account exists with verified email and active status';
        case ActionType.authenticate:
          return 'Registered and verified credentials are available for the authentication attempt';
        case ActionType.create:
          return 'All required fields for creating the $entityName are known and valid with active schema';
        case ActionType.update:
          return 'Updated field values are verified and compliant with active business rules';
        case ActionType.delete:
          return 'Delete permission is verified and active with confirmed member authorization';
        case ActionType.pay:
          return 'Registered payment method is active and verified with sufficient funds';
        case ActionType.checkout:
          return 'Registered cart is active with verified items ready for checkout';
        case ActionType.transfer:
          return 'Source account is active and verified with sufficient balance for transfer amount';
        case ActionType.book:
          return 'Target time slot is active, available, and not already booked';
        case ActionType.view:
          return 'Registered $entityName is active and verified for viewing with valid permissions';
        case ActionType.trigger:
          return 'Webhook secret key is configured, verified, and active on both sides';
        case ActionType.send:
          return 'API request payload is valid, verified, and meets active schema requirements';
        default:
          return 'Registered $entityName is active and ready for ${scenario.action.displayName}';
      }
    } else {
      switch (action) {
        case ActionType.login:
          return 'Invalid or unregistered credentials are prepared with inactive account status';
        case ActionType.authenticate:
          return 'Expired or revoked credentials are available with inactive authentication tokens';
        case ActionType.create:
          return 'Invalid or incomplete input data is prepared for rejection with active validation rules';
        case ActionType.pay:
          return 'Expired or inactive payment method is available with unverified funds for testing';
        case ActionType.transfer:
          return 'Account balance is verified as below the requested transfer amount with inactive funds';
        case ActionType.book:
          return 'Target time slot is inactive, occupied, or outside available range';
        case ActionType.trigger:
          return 'Invalid or missing webhook signature is prepared with inactive endpoint status';
        case ActionType.send:
          return 'Malformed or incomplete payload is available with invalid schema for rejection testing';
        default:
          return 'Registered $entityName is in an inactive state that prevents ${scenario.action.displayName}';
      }
    }
  }

  static String _domainPrerequisite(String domainId, ActionType action, EntityType entity) {
    switch (domainId) {
      case 'identity':
        return 'Authentication service is active and reachable with verified normal response times';
      case 'commerce':
        return 'Inventory service is active and verified product catalog is accessible';
      case 'transaction':
        return 'Banking service is active and verified with transaction processing enabled';
      case 'scheduling':
        return 'Calendar service is active and verified provider schedules are loaded';
      case 'records':
        return 'Active health records service is connected with verified data synchronization';
      case 'integration':
        return 'API gateway is active and reachable with verified rate limit status';
      default:
        return 'Backend services are active and reachable with verified normal response latency';
    }
  }

  static String _negativePrerequisite(Scenario scenario, ActionType action, String entityName) {
    if (action == ActionType.login) {
      return 'No prior successful authentication session exists for validation';
    }
    if (action == ActionType.authorize) {
      return 'Valid OAuth session or browser state is configured for the authorization attempt';
    }
    if (action == ActionType.pay || action == ActionType.transfer) {
      return 'System does not allow bypassing the error state with alternative methods';
    }
    return 'Test environment has malformed or out-of-range input data ready';
  }
}
