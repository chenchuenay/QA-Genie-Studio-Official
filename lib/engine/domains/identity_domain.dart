import '../ontology/states.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../models/domain_context.dart';
import '../ontology/relationships.dart';

class IdentityDomain {
  static const DomainContext context = DomainContext(
    id: 'identity',
    displayName: 'Identity',
    entities: {
      EntityType.account,
      EntityType.credential,
      EntityType.session,
      EntityType.token,
      EntityType.member,
      EntityType.profile,
      EntityType.role,
      EntityType.permission,
      EntityType.password,
      EntityType.otp,
      EntityType.mfa,
      EntityType.oauthProvider,
      EntityType.roleAssignment,
      EntityType.permissionSet,
      EntityType.device,
      EntityType.loginAttempt,
      EntityType.resetToken,
    },
    actions: {
      ActionType.login,
      ActionType.logout,
      ActionType.authenticate,
      ActionType.create,
      ActionType.update,
      ActionType.delete,
      ActionType.verify,
      ActionType.refresh,
      ActionType.authorize,
      ActionType.reset,
      ActionType.validate,
      ActionType.reject,
      ActionType.block,
    },
    states: {
      StateType.active,
      StateType.inactive,
      StateType.locked,
      StateType.authenticated,
      StateType.unauthenticated,
      StateType.authorized,
      StateType.unauthorized,
      StateType.valid,
      StateType.invalid,
      StateType.expired,
      StateType.pending,
      StateType.failed,
    },
  );

  static List<Relationship> getRelationships() {
    return [
      // account <-> credential
      Relationship(
        source: EntityType.account,
        target: EntityType.credential,
        action: ActionType.authenticate,
        fromState: StateType.active,
        toState: StateType.authenticated,
      ),
      Relationship(
        source: EntityType.credential,
        target: EntityType.account,
        action: ActionType.authenticate,
        fromState: StateType.valid,
        toState: StateType.authenticated,
      ),
      Relationship(
        source: EntityType.credential,
        target: EntityType.account,
        action: ActionType.authenticate,
        fromState: StateType.invalid,
        toState: StateType.unauthenticated,
      ),

      // account <-> session
      Relationship(
        source: EntityType.account,
        target: EntityType.session,
        action: ActionType.login,
        fromState: StateType.active,
        toState: StateType.active,
      ),
      Relationship(
        source: EntityType.account,
        target: EntityType.session,
        action: ActionType.login,
        fromState: StateType.locked,
        toState: StateType.failed,
      ),
      Relationship(
        source: EntityType.account,
        target: EntityType.session,
        action: ActionType.login,
        fromState: StateType.inactive,
        toState: StateType.failed,
      ),

      // account <-> password reset
      Relationship(
        source: EntityType.account,
        target: EntityType.password,
        action: ActionType.reset,
        fromState: StateType.active,
        toState: StateType.active,
      ),
      Relationship(
        source: EntityType.resetToken,
        target: EntityType.password,
        action: ActionType.reset,
        fromState: StateType.valid,
        toState: StateType.active,
      ),
      Relationship(
        source: EntityType.resetToken,
        target: EntityType.password,
        action: ActionType.reset,
        fromState: StateType.expired,
        toState: StateType.failed,
      ),

      // account <-> OTP
      Relationship(
        source: EntityType.account,
        target: EntityType.otp,
        action: ActionType.verify,
        fromState: StateType.active,
        toState: StateType.authenticated,
      ),
      Relationship(
        source: EntityType.otp,
        target: EntityType.account,
        action: ActionType.verify,
        fromState: StateType.valid,
        toState: StateType.authenticated,
      ),
      Relationship(
        source: EntityType.otp,
        target: EntityType.account,
        action: ActionType.verify,
        fromState: StateType.invalid,
        toState: StateType.failed,
      ),

      // account <-> OAuth
      Relationship(
        source: EntityType.account,
        target: EntityType.oauthProvider,
        action: ActionType.authorize,
        fromState: StateType.active,
        toState: StateType.authenticated,
      ),
      Relationship(
        source: EntityType.oauthProvider,
        target: EntityType.account,
        action: ActionType.authorize,
        fromState: StateType.valid,
        toState: StateType.authenticated,
      ),
      Relationship(
        source: EntityType.oauthProvider,
        target: EntityType.account,
        action: ActionType.authorize,
        fromState: StateType.invalid,
        toState: StateType.failed,
      ),

      // role assignment & permission set
      Relationship(
        source: EntityType.roleAssignment,
        target: EntityType.permissionSet,
        action: ActionType.assign,
        fromState: StateType.active,
        toState: StateType.active,
      ),
      Relationship(
        source: EntityType.permissionSet,
        target: EntityType.account,
        action: ActionType.authorize,
        fromState: StateType.valid,
        toState: StateType.authorized,
      ),
      Relationship(
        source: EntityType.permissionSet,
        target: EntityType.account,
        action: ActionType.authorize,
        fromState: StateType.invalid,
        toState: StateType.unauthorized,
      ),

      // device
      Relationship(
        source: EntityType.device,
        target: EntityType.session,
        action: ActionType.login,
        fromState: StateType.active,
        toState: StateType.active,
      ),
      Relationship(
        source: EntityType.device,
        target: EntityType.session,
        action: ActionType.login,
        fromState: StateType.pending,
        toState: StateType.pending,
      ),

      // login attempts
      Relationship(
        source: EntityType.loginAttempt,
        target: EntityType.account,
        action: ActionType.block,
        fromState: StateType.exhausted,
        toState: StateType.locked,
      ),

      // logout
      Relationship(
        source: EntityType.account,
        target: EntityType.account,
        action: ActionType.logout,
        fromState: StateType.authenticated,
        toState: StateType.inactive,
      ),

      // refresh session
      Relationship(
        source: EntityType.session,
        target: EntityType.session,
        action: ActionType.refresh,
        fromState: StateType.active,
        toState: StateType.active,
      ),
    ];
  }
}
