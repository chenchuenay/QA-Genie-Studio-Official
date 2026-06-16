import '../models/scenario.dart';
import '../ontology/states.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../models/domain_context.dart';
import '../ontology/relationships.dart';
import '../domains/records_domain.dart';
import '../domains/identity_domain.dart';
import '../domains/commerce_domain.dart';
import '../domains/scheduling_domain.dart';
import '../domains/transaction_domain.dart';
import '../domains/integration_domain.dart';

class ScenarioPlanner {
  final DomainContext domain;
  final Map<String, int> categoryCounts;
  final Set<String> constraintKeywords;
  final Set<EntityType> seedEntities;
  final String constraints;

  ScenarioPlanner({
    required this.domain,
    required this.categoryCounts,
    required this.constraintKeywords,
    required this.seedEntities,
    required this.constraints,
  });

  List<Scenario> plan() {
    final allRelations = _getAllRelationships();
    final reachable = <Relationship>{};
    for (final seed in seedEntities) {
      _expandFromEntity(seed, allRelations, reachable, depth: 0);
    }
    if (reachable.isEmpty) return [];

    final lowerConstraints = constraints.toLowerCase();
    final categoriesToGenerate = categoryCounts.keys.toList();
    if (lowerConstraints.contains('only security'))
      categoriesToGenerate.retainWhere((c) => c == 'security');
    else if (lowerConstraints.contains('only validation'))
      categoriesToGenerate.retainWhere((c) => c == 'validation');
    else if (lowerConstraints.contains('only boundary'))
      categoriesToGenerate.retainWhere((c) => c == 'boundary');

    final scenarios = <Scenario>[];
    final usedFingerprints = <String>{};

    for (final category in categoriesToGenerate) {
      final needed = categoryCounts[category] ?? 0;
      if (needed == 0) continue;
      final conditions = _getConditionsForCategory(category);
      for (final rel in reachable) {
        if (scenarios.length >= needed) break;
        if (rel.action == null || rel.toState == null) continue;
        for (final condition in conditions) {
          if (!_isConditionCompatible(rel, condition)) continue;
          final scenario = Scenario(
            entity: rel.source,
            action: rel.action!,
            targetState: _targetStateForCondition(rel, condition),
            category: category,
          );
          final fingerprint =
              '${scenario.entity.name}|${scenario.action.name}|${condition}|${scenario.targetState.name}';
          if (usedFingerprints.contains(fingerprint)) continue;
          usedFingerprints.add(fingerprint);
          scenarios.add(scenario);
          if (scenarios.length >= needed) break;
        }
      }
    }

    final totalNeeded = categoryCounts.values.fold(0, (a, b) => a + b);
    if (scenarios.length < totalNeeded) {
      if (reachable.isNotEmpty) {
        final defaultRel = reachable.first;
        while (scenarios.length < totalNeeded) {
          scenarios.add(
            Scenario(
              entity: defaultRel.source,
              action: defaultRel.action!,
              targetState: defaultRel.toState ?? StateType.active,
              category: 'positive',
            ),
          );
        }
      } else {
        // ULTIMATE FALLBACK: This should not happen with hardened seed entities
        while (scenarios.length < totalNeeded) {
          scenarios.add(
            Scenario(
              entity: EntityType.account,
              action: ActionType.view,
              targetState: StateType.active,
              category: 'positive',
            ),
          );
        }
      }
    }
    return scenarios.take(totalNeeded).toList();
  }

  void _expandFromEntity(
    EntityType entity,
    List<Relationship> allRelations,
    Set<Relationship> result, {
    int depth = 0,
  }) {
    if (depth > 3) return;
    for (final rel in allRelations) {
      if (rel.source == entity || rel.target == entity) {
        if (result.add(rel)) {
          final next = rel.source == entity ? rel.target : rel.source;
          _expandFromEntity(next, allRelations, result, depth: depth + 1);
        }
      }
    }
  }

  List<String> _getConditionsForCategory(String category) {
    switch (category) {
      case 'positive':
        return ['valid'];
      case 'negative':
        return ['invalid', 'expired', 'locked', 'unauthorized', 'insufficient'];
      case 'validation':
        return [
          'empty',
          'invalid_format',
          'duplicate',
          'max_length',
          'min_length',
        ];
      case 'boundary':
        return ['maximum', 'minimum'];
      case 'security':
        return ['sql_injection', 'xss', 'bruteforce', 'credential_stuffing'];
      case 'session':
        return ['expired', 'revoked', 'concurrent'];
      default:
        return ['valid'];
    }
  }

  bool _isConditionCompatible(Relationship rel, String condition) {
    final action = rel.action;
    if (action == ActionType.login || action == ActionType.authenticate) {
      return ['valid', 'invalid', 'expired', 'locked'].contains(condition);
    }
    if (action == ActionType.pay) {
      return [
        'valid',
        'expired',
        'insufficient',
        'duplicate',
      ].contains(condition);
    }
    if (action == ActionType.apply) {
      return ['valid', 'expired', 'already_used'].contains(condition);
    }
    if (action == ActionType.transfer) {
      return ['valid', 'invalid', 'insufficient'].contains(condition);
    }
    if (action == ActionType.create && rel.source == EntityType.appointment) {
      return ['available', 'unavailable', 'duplicate'].contains(condition);
    }
    return condition == 'valid';
  }

  StateType _targetStateForCondition(Relationship rel, String condition) {
    if (condition == 'valid') return rel.toState ?? StateType.active;
    if (condition == 'expired') return StateType.expired;
    if (condition == 'locked') return StateType.locked;
    if (condition == 'insufficient') return StateType.insufficient;
    if (condition == 'duplicate') return StateType.duplicate;
    if (condition == 'already_used') return StateType.invalid;
    if (condition == 'unavailable') return StateType.unavailable;
    return StateType.failed;
  }

  List<Relationship> _getAllRelationships() {
    switch (domain.id) {
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
}
