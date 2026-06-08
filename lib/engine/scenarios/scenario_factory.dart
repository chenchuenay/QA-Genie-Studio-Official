import '../models/scenario.dart';
import '../ontology/states.dart';
import '../models/domain_context.dart';
import '../ontology/relationships.dart';
import '../domains/records_domain.dart';
import '../domains/identity_domain.dart';
import '../domains/commerce_domain.dart';
import '../domains/scheduling_domain.dart';
import '../domains/transaction_domain.dart';
import '../domains/integration_domain.dart';
import '../domains/cross_domain.dart'; // NEW: cross‑domain relationships

class ScenarioFactory {
  static List<Scenario> fromDomain(DomainContext domain) {
    final scenarios = <Scenario>{};
    // Generate from domain‑specific relationships
    final relationships = _getRelationshipsForDomain(domain.id);
    for (final rel in relationships) {
      if (rel.action != null && rel.fromState != null && rel.toState != null) {
        scenarios.add(
          Scenario(
            entity: rel.source,
            action: rel.action!,
            targetState: rel.toState!,
            category: _inferCategory(rel.toState!),
          ),
        );
      }
    }

    // Add cross‑domain relationships (only once, not per domain)
    // To avoid duplicates, we add them only when building for a domain that can act as source.
    // But for simplicity, add them for every domain – duplicates will be removed by Set.
    for (final rel in CrossDomainRelationships.getAll()) {
      if (rel.action != null && rel.fromState != null && rel.toState != null) {
        scenarios.add(
          Scenario(
            entity: rel.source,
            action: rel.action!,
            targetState: rel.toState!,
            category: _inferCategory(rel.toState!),
          ),
        );
      }
    }

    // If still no scenarios (should not happen with expanded ontology), fallback
    if (scenarios.isEmpty) {
      for (final entity in domain.entities) {
        for (final action in domain.actions) {
          for (final state in domain.states) {
            scenarios.add(
              Scenario(
                entity: entity,
                action: action,
                targetState: state,
                category: 'positive',
              ),
            );
          }
        }
      }
    }
    return scenarios.toList();
  }

  static List<Relationship> _getRelationshipsForDomain(String domainId) {
    switch (domainId) {
      case 'identity':
        return IdentityDomain.getRelationships();
      case 'commerce':
        return CommerceDomain.getRelationships();
      case 'transaction':
        return TransactionDomain.getRelationships();
      case 'scheduling':
        return SchedulingDomain.getRelationships();
      case 'records':
        return RecordsDomain.getRelationships();
      case 'integration':
        return IntegrationDomain.getRelationships();
      default:
        return [];
    }
  }

  static String _inferCategory(StateType toState) {
    // Positive outcomes
    if (toState == StateType.active ||
        toState == StateType.authenticated ||
        toState == StateType.authorized ||
        toState == StateType.completed ||
        toState == StateType.approved ||
        toState == StateType.discounted ||
        toState == StateType.processed ||
        toState == StateType.shared ||
        toState == StateType.deliveredState ||
        toState == StateType.triggered ||
        toState == StateType.accepted ||
        toState == StateType.shipped ||
        toState == StateType.delivered ||
        toState == StateType.refunded ||
        toState == StateType.valid) {
      return 'positive';
    }
    // Negative outcomes
    if (toState == StateType.failed ||
        toState == StateType.invalid ||
        toState == StateType.unauthorized ||
        toState == StateType.rejected ||
        toState == StateType.restricted ||
        toState == StateType.denied ||
        toState == StateType.expired ||
        toState == StateType.locked ||
        toState == StateType.cancelled ||
        toState == StateType.unavailable ||
        toState == StateType.insufficient ||
        toState == StateType.outOfStock ||
        toState == StateType.exhausted ||
        toState == StateType.flagged) {
      return 'negative';
    }
    // Neutral / edge – treat as positive for coverage, but could be boundary/validation later
    return 'positive';
  }
}
