enum EntityType {
  // Identity domain
  account,
  credential,
  session,
  token,
  member,
  profile,
  role,
  permission,
  password,
  otp,
  mfa,
  oauthProvider,
  roleAssignment,
  permissionSet,
  device,
  loginAttempt,
  resetToken,

  // Commerce domain
  cart,
  item,
  product,
  order,
  coupon,
  giftCard,
  payment,
  address,
  shipping,
  inventory,
  receipt,
  refund,
  shippingMethod,
  tax,
  discount,

  // Transaction domain
  wallet,
  transfer,
  transaction,
  balance,
  payee,
  beneficiary,
  accountTx,
  limit,
  schedule,
  fee,

  // Scheduling domain
  appointment,
  provider,
  patient,
  slot,
  calendar,
  availability,
  consultation,
  insurance,
  reminder,
  meetingLink,

  // Records domain
  record,
  labResult,
  prescription,
  document,
  consent,
  insuranceRecord,
  authorization,
  allergy,
  redaction,
  result, // NEW (lab result entity)
  // Integration domain
  webhook,
  apiKey,
  endpoint,
  request,
  response,
  event,
  rateLimit,
  retry,
  callback,
  timeout,
  schema,
  payload, // NEW
}

extension EntityTypeExtension on EntityType {
  String get displayName {
    switch (this) {
      // Identity
      case EntityType.account:
        return 'account';
      case EntityType.credential:
        return 'credential';
      case EntityType.session:
        return 'session';
      case EntityType.token:
        return 'token';
      case EntityType.member:
        return 'member';
      case EntityType.profile:
        return 'profile';
      case EntityType.role:
        return 'role';
      case EntityType.permission:
        return 'permission';
      case EntityType.password:
        return 'password';
      case EntityType.otp:
        return 'OTP';
      case EntityType.mfa:
        return 'MFA';
      case EntityType.oauthProvider:
        return 'OAuth provider';
      case EntityType.roleAssignment:
        return 'role assignment';
      case EntityType.permissionSet:
        return 'permission set';
      case EntityType.device:
        return 'device';
      case EntityType.loginAttempt:
        return 'login attempt';
      case EntityType.resetToken:
        return 'reset token';

      // Commerce
      case EntityType.cart:
        return 'cart';
      case EntityType.item:
        return 'item';
      case EntityType.product:
        return 'product';
      case EntityType.order:
        return 'order';
      case EntityType.coupon:
        return 'coupon';
      case EntityType.giftCard:
        return 'gift card';
      case EntityType.payment:
        return 'payment';
      case EntityType.address:
        return 'address';
      case EntityType.shipping:
        return 'shipping';
      case EntityType.inventory:
        return 'inventory';
      case EntityType.receipt:
        return 'receipt';
      case EntityType.refund:
        return 'refund';
      case EntityType.shippingMethod:
        return 'shipping method';
      case EntityType.tax:
        return 'tax';
      case EntityType.discount:
        return 'discount';

      // Transaction
      case EntityType.wallet:
        return 'wallet';
      case EntityType.transfer:
        return 'transfer';
      case EntityType.transaction:
        return 'transaction';
      case EntityType.balance:
        return 'balance';
      case EntityType.payee:
        return 'payee';
      case EntityType.beneficiary:
        return 'beneficiary';
      case EntityType.accountTx:
        return 'account';
      case EntityType.limit:
        return 'limit';
      case EntityType.schedule:
        return 'schedule';
      case EntityType.fee:
        return 'fee';

      // Scheduling
      case EntityType.appointment:
        return 'appointment';
      case EntityType.provider:
        return 'provider';
      case EntityType.patient:
        return 'patient';
      case EntityType.slot:
        return 'slot';
      case EntityType.calendar:
        return 'calendar';
      case EntityType.availability:
        return 'availability';
      case EntityType.consultation:
        return 'consultation';
      case EntityType.insurance:
        return 'insurance';
      case EntityType.reminder:
        return 'reminder';
      case EntityType.meetingLink:
        return 'meeting link';

      // Records
      case EntityType.record:
        return 'record';
      case EntityType.labResult:
        return 'lab result';
      case EntityType.prescription:
        return 'prescription';
      case EntityType.document:
        return 'document';
      case EntityType.consent:
        return 'consent';
      case EntityType.insuranceRecord:
        return 'insurance record';
      case EntityType.authorization:
        return 'authorization';
      case EntityType.allergy:
        return 'allergy';
      case EntityType.redaction:
        return 'redaction';
      case EntityType.result:
        return 'result';

      // Integration
      case EntityType.webhook:
        return 'webhook';
      case EntityType.apiKey:
        return 'API key';
      case EntityType.endpoint:
        return 'endpoint';
      case EntityType.request:
        return 'request';
      case EntityType.response:
        return 'response';
      case EntityType.event:
        return 'event';
      case EntityType.rateLimit:
        return 'rate limit';
      case EntityType.retry:
        return 'retry';
      case EntityType.callback:
        return 'callback';
      case EntityType.timeout:
        return 'timeout';
      case EntityType.schema:
        return 'schema';
      case EntityType.payload:
        return 'payload';
    }
  }
}
