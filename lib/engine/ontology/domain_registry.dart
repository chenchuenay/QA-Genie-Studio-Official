enum EntityState { idle, inMotion, initialized, processed, error, authenticated, approved }

class ActionPattern {
  final List<EntityState> requiredPreconditions;
  final EntityState postCondition;
  final Map<String, List<String>> stepsByPlatform;
  final List<String> requiredConstraints;

  ActionPattern({
    required this.requiredPreconditions,
    required this.postCondition,
    required this.stepsByPlatform,
    this.requiredConstraints = const [],
  });
}

class DomainRegistry {
  static final Map<String, Map<String, ActionPattern>> ontology = {
    'Robotics': {
      'Move': ActionPattern(
        requiredPreconditions: [EntityState.idle],
        postCondition: EntityState.inMotion,
        stepsByPlatform: {
          'Mobile': ['TapVelocityInput', 'EnterVector', 'VerifyMotionSensor'],
          'API': ['CommandMoveVector', 'VerifyResponse']
        }
      ),
      'EmergencyStop': ActionPattern(
        requiredPreconditions: [EntityState.inMotion],
        postCondition: EntityState.error,
        stepsByPlatform: {
          'Mobile': ['TapEmergencyStop', 'VerifySafeMode'],
          'API': ['PostEmergencyCommand', 'VerifySafeState']
        }
      ),
    },
    'AI': {
      'Generate': ActionPattern(
        requiredPreconditions: [EntityState.initialized],
        postCondition: EntityState.processed,
        stepsByPlatform: {
          'Web': ['ClickPromptInput', 'EnterPromptText', 'ClickGenerate', 'VerifyOutput'],
          'API': ['PostPromptPayload', 'VerifyTokenResponse']
        },
        requiredConstraints: ['tokenLimit', 'guardrail']
      ),
    },
    'Sales': {
      'Checkout': ActionPattern(
        requiredPreconditions: [EntityState.authenticated],
        postCondition: EntityState.processed,
        stepsByPlatform: {
          'Web': ['SelectCartItems', 'ProceedToCheckout', 'EnterPaymentDetails', 'SubmitOrder'],
          'API': ['PostCheckoutPayload', 'VerifyPaymentResponse']
        },
        requiredConstraints: ['budgetCheck', 'duplicateDetection']
      ),
    },
    'HR': {
      'TimeOff': ActionPattern(
        requiredPreconditions: [EntityState.initialized],
        postCondition: EntityState.approved,
        stepsByPlatform: {
          'Web': ['SelectDates', 'SubmitRequest', 'VerifyStatus'],
          'Mobile': ['TapLeaveMenu', 'EnterDates', 'TapSubmit']
        },
        requiredConstraints: ['balanceCheck', 'blackoutDateCheck']
      ),
    },
    'DevOps': {
      'Deploy': ActionPattern(
        requiredPreconditions: [EntityState.initialized],
        postCondition: EntityState.processed,
        stepsByPlatform: {
          'API': ['TriggerPipeline', 'MonitorBuild', 'VerifyDeployment']
        },
        requiredConstraints: ['coverageThreshold', 'approvalGate']
      ),
    }
  };
}
