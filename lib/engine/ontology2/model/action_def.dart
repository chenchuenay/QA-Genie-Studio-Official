import 'entity_def.dart';
import 'state_def.dart';

class ActionCategory {
  final String id;
  final String displayName;

  const ActionCategory({required this.id, required this.displayName});

  static const auth = ActionCategory(id: 'auth', displayName: 'Authentication');
  static const crud = ActionCategory(id: 'crud', displayName: 'CRUD');
  static const commerce = ActionCategory(id: 'commerce', displayName: 'Commerce');
  static const transaction = ActionCategory(id: 'transaction', displayName: 'Transaction');
  static const communication = ActionCategory(id: 'communication', displayName: 'Communication');
  static const scheduling = ActionCategory(id: 'scheduling', displayName: 'Scheduling');
  static const deployment = ActionCategory(id: 'deployment', displayName: 'Deployment');
  static const execution = ActionCategory(id: 'execution', displayName: 'Execution');
  static const navigation = ActionCategory(id: 'navigation', displayName: 'Navigation');
  static const sharing = ActionCategory(id: 'sharing', displayName: 'Sharing');
  static const administration = ActionCategory(id: 'administration', displayName: 'Administration');
  static const analytics = ActionCategory(id: 'analytics', displayName: 'Analytics');
}

class ActionDef {
  final String id;
  final String displayName;
  final String verb;
  final String pastTense;
  final String preposition;
  final ActionCategory category;
  final List<String> requiredPropertyNames;
  final List<String> optionalPropertyNames;
  final List<StateTransition> transitions;

  const ActionDef({
    required this.id,
    required this.displayName,
    required this.verb,
    this.pastTense = '',
    this.preposition = '',
    required this.category,
    this.requiredPropertyNames = const [],
    this.optionalPropertyNames = const [],
    this.transitions = const [],
  });

  String get pastTenseEffective => pastTense.isNotEmpty ? pastTense : '${verb}ed';

  String resolveButtonLabel(EntityDef entityDef) {
    return '$verb $entityDef';
  }
}
