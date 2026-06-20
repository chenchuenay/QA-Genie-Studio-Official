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
      final relList = reachable.toList();
      int relIndex = 0;
      int catCount = 0;
      while (catCount < needed) {
        for (final condition in conditions) {
          if (catCount >= needed) break;
          for (int r = 0; r < relList.length; r++) {
            if (catCount >= needed) break;
            final rel = relList[(relIndex + r) % relList.length];
            if (rel.action == null || rel.toState == null) continue;
            if (!_isConditionCompatible(rel, condition)) continue;
            final scenario = Scenario(
              entity: rel.source,
              action: rel.action!,
              targetState: _targetStateForCondition(rel, condition),
              category: category,
              condition: condition,
            );
            final fingerprint =
                '${scenario.entity.name}|${scenario.action.name}|${condition}|${scenario.targetState.name}';
            if (usedFingerprints.contains(fingerprint)) continue;
            usedFingerprints.add(fingerprint);
            scenarios.add(scenario);
            catCount++;
          }
        }
        relIndex++;
        if (relIndex > 5) break; // safety valve
      }
    }

    final totalNeeded = categoryCounts.values.fold(0, (a, b) => a + b);
    if (scenarios.length < totalNeeded) {
      if (reachable.isNotEmpty) {
        final relList = reachable.toList();
        final fallbackConditions = <String>['valid', 'invalid', 'expired', 'locked', 'empty'];
        int ri = 0, ci = 0;
        int lastSize = scenarios.length;
        int stalledCycles = 0;
        while (scenarios.length < totalNeeded) {
          final rel = relList[ri % relList.length];
          final cond = fallbackConditions[ci % fallbackConditions.length];
          ri++;
          ci++;
          if (rel.action == null || rel.toState == null) continue;
          final scenario = Scenario(
            entity: rel.source,
            action: rel.action!,
            targetState: _targetStateForCondition(rel, cond),
            category: 'positive',
            condition: cond,
          );
          final fp = '${scenario.entity.name}|${scenario.action.name}|$cond|${scenario.targetState.name}';
          if (usedFingerprints.add(fp)) {
            scenarios.add(scenario);
          }
          // Safety valve: if a full cycle completes without progress, break
          if (ri % relList.length == 0 && ci % fallbackConditions.length == 0) {
            if (scenarios.length == lastSize) {
              stalledCycles++;
              if (stalledCycles >= 2) break;
            } else {
              lastSize = scenarios.length;
              stalledCycles = 0;
            }
          }
        }
      } else {
        final fallbackPairs = [(EntityType.account, ActionType.login, 'valid'),
                               (EntityType.credential, ActionType.create, 'empty'),
                               (EntityType.session, ActionType.refresh, 'expired')];
        int fi = 0;
        while (scenarios.length < totalNeeded) {
          final pair = fallbackPairs[fi % fallbackPairs.length];
          final scenario = Scenario(
            entity: pair.$1,
            action: pair.$2,
            targetState: StateType.active,
            category: 'positive',
            condition: pair.$3,
          );
          scenarios.add(scenario);
          fi++;
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
    // Security/validation/boundary/session conditions are universal
    if (['sql_injection', 'xss', 'bruteforce', 'credential_stuffing',
         'empty', 'invalid_format', 'duplicate', 'max_length', 'min_length',
         'maximum', 'minimum',
         'expired', 'revoked', 'concurrent'].contains(condition)) {
      return true;
    }
    final action = rel.action;
    if (action == ActionType.login || action == ActionType.authenticate) {
      return condition == 'valid' || condition == 'invalid' || condition == 'locked';
    }
    if (action == ActionType.pay) {
      return ['valid', 'expired', 'insufficient', 'duplicate'].contains(condition);
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
