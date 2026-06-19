import '../ontology/states.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../models/domain_context.dart';
import '../ontology/relationships.dart';

class RecordsDomain {
  static const DomainContext context = DomainContext(
    id: 'records',
    displayName: 'Records',
    entities: {
      EntityType.record,
      EntityType.labResult,
      EntityType.prescription,
      EntityType.document,
      EntityType.consent,
      EntityType.insuranceRecord,
      EntityType.authorization,
      EntityType.allergy,
      EntityType.redaction,
    },
    actions: {
      ActionType.view,
      ActionType.update,
      ActionType.create,
      ActionType.delete,
      ActionType.verify,
      ActionType.authorize,
      ActionType.accessGranted,
      ActionType.accessDenied,
      ActionType.requestRefill,
      ActionType.flag,
      ActionType.mask,
      ActionType.share,
      ActionType.restrict,
    },
    states: {
      StateType.active,
      StateType.inactive,
      StateType.pending,
      StateType.approved,
      StateType.denied,
      StateType.valid,
      StateType.invalid,
      StateType.expired,
      StateType.abnormal,
      StateType.normal,
      StateType.shared,
      StateType.restricted,
      StateType.masked,
      StateType.flagged,
    },
  );

  static List<Relationship> getRelationships() {
    return [
      // patient access
      Relationship(
        source: EntityType.patient,
        target: EntityType.record,
        action: ActionType.view,
        fromState: StateType.active,
        toState: StateType.active,
      ),

      // authorization
      Relationship(
        source: EntityType.authorization,
        target: EntityType.record,
        action: ActionType.accessGranted,
        fromState: StateType.valid,
        toState: StateType.shared,
      ),
      Relationship(
        source: EntityType.authorization,
        target: EntityType.record,
        action: ActionType.accessDenied,
        fromState: StateType.invalid,
        toState: StateType.restricted,
      ),

      // lab results
      Relationship(
        source: EntityType.labResult,
        target: EntityType.result,
        action: ActionType.view,
        fromState: StateType.normal,
        toState: StateType.active,
      ),
      Relationship(
        source: EntityType.labResult,
        target: EntityType.result,
        action: ActionType.flag,
        fromState: StateType.abnormal,
        toState: StateType.flagged,
      ),

      // prescription & refill
      Relationship(
        source: EntityType.prescription,
        target: EntityType.prescription,
        action: ActionType.requestRefill,
        fromState: StateType.active,
        toState: StateType.pending,
      ),
      Relationship(
        source: EntityType.prescription,
        target: EntityType.prescription,
        action: ActionType.requestRefill,
        fromState: StateType.expired,
        toState: StateType.rejected,
      ),

      // allergy blocking
      Relationship(
        source: EntityType.allergy,
        target: EntityType.prescription,
        action: ActionType.block,
        fromState: StateType.active,
        toState: StateType.failed,
      ),

      // consent
      Relationship(
        source: EntityType.consent,
        target: EntityType.record,
        action: ActionType.share,
        fromState: StateType.valid,
        toState: StateType.shared,
      ),
      Relationship(
        source: EntityType.consent,
        target: EntityType.record,
        action: ActionType.restrict,
        fromState: StateType.expired,
        toState: StateType.restricted,
      ),

      // create record
      Relationship(
        source: EntityType.patient,
        target: EntityType.record,
        action: ActionType.create,
        fromState: StateType.active,
        toState: StateType.active,
      ),

      // delete record
      Relationship(
        source: EntityType.record,
        target: EntityType.record,
        action: ActionType.delete,
        fromState: StateType.active,
        toState: StateType.inactive,
      ),

      // redaction
      Relationship(
        source: EntityType.redaction,
        target: EntityType.document,
        action: ActionType.mask,
        fromState: StateType.required,
        toState: StateType.masked,
      ),

      // insurance verification
      Relationship(
        source: EntityType.insuranceRecord,
        target: EntityType.record,
        action: ActionType.verify,
        fromState: StateType.valid,
        toState: StateType.approved,
      ),
    ];
  }
}
