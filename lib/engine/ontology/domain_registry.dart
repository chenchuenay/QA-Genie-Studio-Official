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
    'Identity': {
      'login': ActionPattern(
        requiredPreconditions: [EntityState.idle],
        postCondition: EntityState.authenticated,
        stepsByPlatform: {
          'Mobile': ['TapLoginField', 'EnterCredentials', 'TapSubmit', 'VerifyDashboard'],
          'Web': ['ClickLoginButton', 'EnterEmailAndPassword', 'ClickSubmit', 'VerifyLandingPage'],
          'API': ['PostAuthPayload', 'ReceiveToken', 'VerifyStatusCode200']
        },
      ),
      'reset': ActionPattern(
        requiredPreconditions: [EntityState.idle],
        postCondition: EntityState.initialized,
        stepsByPlatform: {
          'Mobile': ['TapForgotPassword', 'EnterEmail', 'VerifyEmailSent'],
          'Web': ['ClickResetLink', 'EnterNewPassword', 'ClickConfirm', 'VerifySuccessToast'],
        },
      ),
    },
    'Commerce': {
      'add': ActionPattern(
        requiredPreconditions: [EntityState.initialized],
        postCondition: EntityState.processed,
        stepsByPlatform: {
          'Mobile': ['BrowseCatalog', 'TapAddToCart', 'VerifyCartBadge'],
          'Web': ['SelectProduct', 'ClickAddToBag', 'VerifyCartSidebar'],
          'API': ['PostAddToCartPayload', 'VerifyCartCount']
        },
      ),
      'checkout': ActionPattern(
        requiredPreconditions: [EntityState.authenticated],
        postCondition: EntityState.processed,
        stepsByPlatform: {
          'Web': ['SelectCartItems', 'ProceedToCheckout', 'EnterPaymentDetails', 'SubmitOrder'],
          'Mobile': ['TapCartIcon', 'TapCheckout', 'EnterShippingInfo', 'PlaceOrder'],
          'API': ['PostCheckoutPayload', 'VerifyPaymentResponse']
        },
      ),
    },
    'Transaction': {
      'transfer': ActionPattern(
        requiredPreconditions: [EntityState.authenticated],
        postCondition: EntityState.processed,
        stepsByPlatform: {
          'Mobile': ['TapTransferMenu', 'SelectRecipient', 'EnterAmount', 'VerifyOTP'],
          'Web': ['ClickMoveMoney', 'ChooseAccount', 'InputAmount', 'ClickConfirm'],
          'API': ['PostTransferPayload', 'VerifyTransactionID']
        },
      ),
    },
    'Scheduling': {
      'create': ActionPattern(
        requiredPreconditions: [EntityState.initialized],
        postCondition: EntityState.approved,
        stepsByPlatform: {
          'Web': ['SelectDates', 'SubmitRequest', 'VerifyStatus'],
          'Mobile': ['TapLeaveMenu', 'EnterDates', 'TapSubmit']
        },
      ),
    },
    'Records': {
      'view': ActionPattern(
        requiredPreconditions: [EntityState.authenticated],
        postCondition: EntityState.processed,
        stepsByPlatform: {
          'Web': ['NavigateToRecords', 'ClickViewDetail', 'VerifyDataLoad'],
          'Mobile': ['TapDocuments', 'OpenPDF', 'VerifyContentVisibility']
        },
      ),
    },
    'Integration': {
      'send': ActionPattern(
        requiredPreconditions: [EntityState.initialized],
        postCondition: EntityState.processed,
        stepsByPlatform: {
          'API': ['TriggerPipeline', 'MonitorBuild', 'VerifyDeployment']
        },
      ),
    }
  };
}
