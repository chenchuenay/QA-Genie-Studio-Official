import 'dart:math';

import '../model/entity_def.dart';
import '../model/action_def.dart';
import '../model/domain_ontology.dart';

class OntologyPreconditionGenerator {
  static List<String> generate(
    String category,
    String condition,
    bool isPositive,
    EntityDef entity,
    ActionDef action,
    DomainOntology domain, {
    int seed = 0,
  }) {
    final rng = Random(seed);
    final preconditions = <String>[
      _entityPrecondition(entity, action, rng),
      _actionPrecondition(isPositive, entity, action),
      _domainPrerequisite(domain),
    ];

    if (!isPositive) {
      preconditions.add(_negativePrerequisite(action));
    }

    return preconditions;
  }

  static String _entityPrecondition(EntityDef entity, ActionDef action, Random rng) {
    final required = entity.requiredProperties;
    if (required.isEmpty) {
      return 'Valid ${entity.displayName} exists and is accessible';
    }

    final parts = <String>[];
    for (final prop in required.take(2)) {
      if (prop.isIdentifier) {
        parts.add('Valid ${prop.effectiveLabel} is available');
      } else if (prop.isSensitive) {
        parts.add('${prop.effectiveLabel} meets complexity requirements');
      }
    }
    if (parts.isEmpty) {
      parts.add('${entity.displayName} has all required fields available');
    }
    return parts.join(' and ');
  }

  static String _actionPrecondition(bool isPositive, EntityDef entity, ActionDef action) {
    if (isPositive) {
      return '${entity.displayName} is ready for ${action.displayName}';
    } else {
      return '${entity.displayName} is in a state that prevents ${action.displayName}';
    }
  }

  static String _domainPrerequisite(DomainOntology domain) {
    return '${domain.displayName} service is active and reachable';
  }

  static String _negativePrerequisite(ActionDef action) {
    switch (action.id) {
      case 'login':
      case 'authenticate':
        return 'Invalid credentials are prepared for the authentication attempt';
      case 'authorize':
        return 'OAuth error state or invalid redirect is configured for the authorization attempt';
      case 'refresh':
        return 'Expired or revoked token is available for the refresh attempt';
      default:
        return 'Invalid or malformed input data is ready for the operation';
    }
  }
}
