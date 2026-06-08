import '../ontology/states.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../models/domain_context.dart';
import '../ontology/relationships.dart';

class SchedulingDomain {
  static const DomainContext context = DomainContext(
    id: 'scheduling',
    displayName: 'Scheduling',
    entities: {
      EntityType.appointment,
      EntityType.provider,
      EntityType.patient,
      EntityType.slot,
      EntityType.calendar,
      EntityType.availability,
      EntityType.consultation,
      EntityType.insurance,
      EntityType.reminder,
      EntityType.meetingLink,
    },
    actions: {
      ActionType.create,
      ActionType.cancel,
      ActionType.reschedule,
      ActionType.view,
      ActionType.confirm,
      ActionType.join,
      ActionType.book,
      ActionType.sendReminder,
    },
    states: {
      StateType.available,
      StateType.booked,
      StateType.cancelled,
      StateType.confirmed,
      StateType.pending,
      StateType.expired,
      StateType.valid,
      StateType.invalid,
      StateType.active,
      StateType.unavailable,
      StateType.approved,
      StateType.rejected,
    },
  );

  static List<Relationship> getRelationships() {
    return [
      // patient creates appointment
      Relationship(
        source: EntityType.patient,
        target: EntityType.appointment,
        action: ActionType.create,
        fromState: StateType.active,
        toState: StateType.pending,
      ),

      // slot booking
      Relationship(
        source: EntityType.appointment,
        target: EntityType.slot,
        action: ActionType.book,
        fromState: StateType.available,
        toState: StateType.booked,
      ),
      Relationship(
        source: EntityType.slot,
        target: EntityType.appointment,
        action: ActionType.book,
        fromState: StateType.available,
        toState: StateType.confirmed,
      ),
      Relationship(
        source: EntityType.slot,
        target: EntityType.appointment,
        action: ActionType.book,
        fromState: StateType.booked,
        toState: StateType.failed,
      ),

      // provider availability
      Relationship(
        source: EntityType.provider,
        target: EntityType.appointment,
        action: ActionType.confirm,
        fromState: StateType.active,
        toState: StateType.confirmed,
      ),
      Relationship(
        source: EntityType.provider,
        target: EntityType.appointment,
        action: ActionType.confirm,
        fromState: StateType.unavailable,
        toState: StateType.failed,
      ),

      // insurance validation
      Relationship(
        source: EntityType.insurance,
        target: EntityType.appointment,
        action: ActionType.verify,
        fromState: StateType.valid,
        toState: StateType.approved,
      ),
      Relationship(
        source: EntityType.insurance,
        target: EntityType.appointment,
        action: ActionType.verify,
        fromState: StateType.invalid,
        toState: StateType.rejected,
      ),

      // reminder
      Relationship(
        source: EntityType.appointment,
        target: EntityType.reminder,
        action: ActionType.sendReminder,
        fromState: StateType.booked,
        toState: StateType.active,
      ),

      // consultation
      Relationship(
        source: EntityType.appointment,
        target: EntityType.consultation,
        action: ActionType.join,
        fromState: StateType.booked,
        toState: StateType.active,
      ),

      // meeting link
      Relationship(
        source: EntityType.consultation,
        target: EntityType.meetingLink,
        action: ActionType.generate,
        fromState: StateType.active,
        toState: StateType.active,
      ),

      // cancel / reschedule
      Relationship(
        source: EntityType.appointment,
        target: EntityType.appointment,
        action: ActionType.cancel,
        fromState: StateType.booked,
        toState: StateType.cancelled,
      ),
      Relationship(
        source: EntityType.appointment,
        target: EntityType.appointment,
        action: ActionType.reschedule,
        fromState: StateType.booked,
        toState: StateType.booked,
      ),
    ];
  }
}
