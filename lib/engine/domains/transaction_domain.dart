import '../ontology/states.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../models/domain_context.dart';
import '../ontology/relationships.dart';

class TransactionDomain {
  static const DomainContext context = DomainContext(
    id: 'transaction',
    displayName: 'Transaction',
    entities: {
      EntityType.wallet,
      EntityType.transfer,
      EntityType.transaction,
      EntityType.balance,
      EntityType.payee,
      EntityType.beneficiary,
      EntityType.accountTx,
      EntityType.limit,
      EntityType.schedule,
      EntityType.fee,
    },
    actions: {
      ActionType.transfer,
      ActionType.deposit,
      ActionType.withdraw,
      ActionType.schedule,
      ActionType.view,
      ActionType.cancel,
      ActionType.execute,
    },
    states: {
      StateType.active,
      StateType.pending,
      StateType.completed,
      StateType.failed,
      StateType.sufficient,
      StateType.insufficient,
      StateType.valid,
      StateType.invalid,
      StateType.withinRange,
      StateType.exceeded,
      StateType.rejected,
    },
  );

  static List<Relationship> getRelationships() {
    return [
      // balance view
      Relationship(
        source: EntityType.accountTx,
        target: EntityType.balance,
        action: ActionType.view,
        fromState: StateType.active,
        toState: StateType.active,
      ),

      // transfer with sufficient balance
      Relationship(
        source: EntityType.accountTx,
        target: EntityType.beneficiary,
        action: ActionType.transfer,
        fromState: StateType.sufficient,
        toState: StateType.completed,
      ),
      Relationship(
        source: EntityType.accountTx,
        target: EntityType.beneficiary,
        action: ActionType.transfer,
        fromState: StateType.insufficient,
        toState: StateType.failed,
      ),

      // beneficiary validation
      Relationship(
        source: EntityType.beneficiary,
        target: EntityType.transfer,
        action: ActionType.transfer,
        fromState: StateType.valid,
        toState: StateType.completed,
      ),
      Relationship(
        source: EntityType.beneficiary,
        target: EntityType.transfer,
        action: ActionType.transfer,
        fromState: StateType.invalid,
        toState: StateType.rejected,
      ),

      // limits
      Relationship(
        source: EntityType.limit,
        target: EntityType.transfer,
        action: ActionType.transfer,
        fromState: StateType.withinRange,
        toState: StateType.completed,
      ),
      Relationship(
        source: EntityType.limit,
        target: EntityType.transfer,
        action: ActionType.transfer,
        fromState: StateType.exceeded,
        toState: StateType.failed,
      ),

      // pending -> completed
      Relationship(
        source: EntityType.transfer,
        target: EntityType.transaction,
        action: ActionType.execute,
        fromState: StateType.pending,
        toState: StateType.completed,
      ),

      // duplicate detection
      Relationship(
        source: EntityType.transaction,
        target: EntityType.transfer,
        action: ActionType.reject,
        fromState: StateType.duplicate,
        toState: StateType.rejected,
      ),

      // scheduled transfers
      Relationship(
        source: EntityType.schedule,
        target: EntityType.transfer,
        action: ActionType.execute,
        fromState: StateType.active,
        toState: StateType.completed,
      ),

      // fees
      Relationship(
        source: EntityType.fee,
        target: EntityType.transaction,
        action: ActionType.calculate,
        fromState: StateType.valid,
        toState: StateType.processed,
      ),
    ];
  }
}
