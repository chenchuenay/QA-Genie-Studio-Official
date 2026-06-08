import '../ontology/states.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../ontology/relationships.dart';

class CrossDomainRelationships {
  static List<Relationship> getAll() {
    return [
      // identity -> commerce
      Relationship(
        source: EntityType.account,
        target: EntityType.cart,
        action: ActionType.authenticate,
        fromState: StateType.authenticated,
        toState: StateType.active,
      ),
      // identity -> transaction
      Relationship(
        source: EntityType.account,
        target: EntityType.accountTx,
        action: ActionType.authenticate,
        fromState: StateType.authenticated,
        toState: StateType.active,
      ),
      // identity -> records
      Relationship(
        source: EntityType.account,
        target: EntityType.record,
        action: ActionType.authorize,
        fromState: StateType.authenticated,
        toState: StateType.accessGranted,
      ),
      // identity -> scheduling
      Relationship(
        source: EntityType.account,
        target: EntityType.appointment,
        action: ActionType.authenticate,
        fromState: StateType.authenticated,
        toState: StateType.pending, // fixed: was StateType.create
      ),
      // transaction -> commerce
      Relationship(
        source: EntityType.payment,
        target: EntityType.order,
        action: ActionType.pay,
        fromState: StateType.completed,
        toState: StateType.paid,
      ),
      // scheduling -> integration
      Relationship(
        source: EntityType.consultation,
        target: EntityType.endpoint,
        action: ActionType.join,
        fromState: StateType.active,
        toState: StateType.active,
      ),
    ];
  }
}
