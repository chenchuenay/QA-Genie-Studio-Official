import '../ontology/states.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../models/domain_context.dart';
import '../ontology/relationships.dart';

class IntegrationDomain {
  static const DomainContext context = DomainContext(
    id: 'integration',
    displayName: 'Integration',
    entities: {
      EntityType.webhook,
      EntityType.apiKey,
      EntityType.endpoint,
      EntityType.request,
      EntityType.response,
      EntityType.event,
      EntityType.rateLimit,
      EntityType.retry,
      EntityType.callback,
      EntityType.timeout,
      EntityType.schema,
    },
    actions: {
      ActionType.send,
      ActionType.receive,
      ActionType.call,
      ActionType.webhookTrigger,
      ActionType.verify,
      ActionType.authenticate,
      ActionType.trigger,
      ActionType.deliver,
      ActionType.retryOp,
    },
    states: {
      StateType.active,
      StateType.inactive,
      StateType.pending,
      StateType.completed,
      StateType.failed,
      StateType.valid,
      StateType.invalid,
      StateType.expired,
      StateType.processed,
      StateType.rejected,
      StateType.deliveredState,
      StateType.triggered,
      StateType.accepted,
      StateType.exhausted,
    },
  );

  static List<Relationship> getRelationships() {
    return [
      // request processing
      Relationship(
        source: EntityType.request,
        target: EntityType.endpoint,
        action: ActionType.send,
        fromState: StateType.valid,
        toState: StateType.processed,
      ),
      Relationship(
        source: EntityType.request,
        target: EntityType.endpoint,
        action: ActionType.send,
        fromState: StateType.invalid,
        toState: StateType.rejected,
      ),

      // payload validation
      Relationship(
        source: EntityType.payload,
        target: EntityType.response,
        action: ActionType.send,
        fromState: StateType.valid,
        toState: StateType.completed,
      ),
      Relationship(
        source: EntityType.payload,
        target: EntityType.response,
        action: ActionType.send,
        fromState: StateType.invalid,
        toState: StateType.failed,
      ),

      // API key authentication
      Relationship(
        source: EntityType.apiKey,
        target: EntityType.request,
        action: ActionType.authenticate,
        fromState: StateType.valid,
        toState: StateType.processed,
      ),
      Relationship(
        source: EntityType.apiKey,
        target: EntityType.request,
        action: ActionType.authenticate,
        fromState: StateType.expired,
        toState: StateType.rejected,
      ),

      // webhook
      Relationship(
        source: EntityType.webhook,
        target: EntityType.event,
        action: ActionType.trigger,
        fromState: StateType.active,
        toState: StateType.triggered,
      ),
      Relationship(
        source: EntityType.event,
        target: EntityType.callback,
        action: ActionType.deliver,
        fromState: StateType.triggered,
        toState: StateType.deliveredState,
      ),
      Relationship(
        source: EntityType.event,
        target: EntityType.retry,
        action: ActionType.retryOp,
        fromState: StateType.failed,
        toState: StateType.pending,
      ),
      Relationship(
        source: EntityType.retry,
        target: EntityType.event,
        action: ActionType.retryOp,
        fromState: StateType.successful,
        toState: StateType.deliveredState,
      ),
      Relationship(
        source: EntityType.retry,
        target: EntityType.event,
        action: ActionType.retryOp,
        fromState: StateType.exhausted,
        toState: StateType.failed,
      ),

      // rate limiting
      Relationship(
        source: EntityType.rateLimit,
        target: EntityType.request,
        action: ActionType.send,
        fromState: StateType.withinRange,
        toState: StateType.processed,
      ),
      Relationship(
        source: EntityType.rateLimit,
        target: EntityType.request,
        action: ActionType.send,
        fromState: StateType.exceeded,
        toState: StateType.rejected,
      ),

      // timeout
      Relationship(
        source: EntityType.timeout,
        target: EntityType.response,
        action: ActionType.call,
        fromState: StateType.expired,
        toState: StateType.failed,
      ),

      // schema validation
      Relationship(
        source: EntityType.schema,
        target: EntityType.payload,
        action: ActionType.verify,
        fromState: StateType.valid,
        toState: StateType.accepted,
      ),
      Relationship(
        source: EntityType.schema,
        target: EntityType.payload,
        action: ActionType.verify,
        fromState: StateType.invalid,
        toState: StateType.rejected,
      ),
    ];
  }
}
