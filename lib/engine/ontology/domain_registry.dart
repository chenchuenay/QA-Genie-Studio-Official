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
      'authorize': ActionPattern(
        requiredPreconditions: [EntityState.idle],
        postCondition: EntityState.authenticated,
        stepsByPlatform: {
          'Mobile': ['TapSignInWithGoogle', 'SelectGoogleAccount', 'ApproveConsentScreen', 'VerifyRedirectWithCode'],
          'Web': ['ClickSignInWithGoogle', 'SelectGoogleAccount', 'ApproveConsentScreen', 'VerifyRedirectWithCode'],
          'API': ['PostOAuthAuthorizePayload', 'ReceiveAuthCode', 'ExchangeCodeForTokens'],
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
          'Web': ['NavigateToDateRange', 'SubmitRequestForm', 'VerifyApprovalStatus'],
          'Mobile': ['TapLeaveMenu', 'EnterLeaveDates', 'TapSubmitRequest']
        },
      ),
    },
    'Records': {
      'view': ActionPattern(
        requiredPreconditions: [EntityState.authenticated],
        postCondition: EntityState.processed,
        stepsByPlatform: {
          'Web': ['NavigateToRecords', 'ClickViewDetail', 'VerifyDataLoad'],
          'Mobile': ['TapDocuments', 'OpenPDFDocument', 'VerifyContentVisibility']
        },
      ),
      'create': ActionPattern(
        requiredPreconditions: [EntityState.authenticated],
        postCondition: EntityState.processed,
        stepsByPlatform: {
          'Web': ['NavigateToRecords', 'ClickAddNewRecord', 'FillPatientInfo', 'ClickSaveRecord', 'VerifyRecordCreated'],
          'Mobile': ['TapRecordsMenu', 'TapAddRecord', 'EnterPatientData', 'TapSaveRecord', 'VerifyRecordAdded'],
        },
      ),
      'delete': ActionPattern(
        requiredPreconditions: [EntityState.authenticated],
        postCondition: EntityState.processed,
        stepsByPlatform: {
          'Web': ['NavigateToRecords', 'ClickDeleteRecord', 'ConfirmDeletion', 'VerifyRecordRemoved'],
          'Mobile': ['TapRecordsMenu', 'TapDeleteRecord', 'ConfirmDeletion', 'VerifyRecordRemoved'],
        },
      ),
    },
    'Integration': {
      'send': ActionPattern(
        requiredPreconditions: [EntityState.initialized],
        postCondition: EntityState.processed,
        stepsByPlatform: {
          'API': ['ClickTriggerPipeline', 'MonitorBuildStatus', 'VerifyDeploymentSuccess']
        },
      ),
    }
  };
}
