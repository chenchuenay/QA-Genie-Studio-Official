enum StateType {
  // Generic
  active,
  inactive,
  pending,
  confirmed,
  cancelled,
  expired,
  available,
  unavailable,
  booked,
  completed,
  failed,
  locked,
  valid,
  invalid,
  sufficient,
  insufficient,
  duplicate,
  outOfStock,
  paid,
  unpaid,
  shipped,
  delivered,
  refunded,

  // Identity specific
  authenticated,
  unauthenticated,
  authorized,
  unauthorized,
  approved,
  denied,
  abnormal,

  // Additional for relationships
  discounted,
  rejected,
  processed,
  shared,
  restricted,
  masked,
  flagged,
  deliveredState,
  triggered,
  accepted,
  exhausted,

  // NEW missing states
  accessGranted,
  accessDenied,
  withinRange,
  exceeded,
  successful,
  normal,
  // Additional states for expected results
  updated,
  deleted,
  scheduled,
  redirected,
  required,
  created, // for appointment creation
}

extension StateTypeExtension on StateType {
  String get displayName {
    switch (this) {
      case StateType.active:
        return 'active';
      case StateType.inactive:
        return 'inactive';
      case StateType.pending:
        return 'pending';
      case StateType.confirmed:
        return 'confirmed';
      case StateType.cancelled:
        return 'cancelled';
      case StateType.expired:
        return 'expired';
      case StateType.available:
        return 'available';
      case StateType.unavailable:
        return 'unavailable';
      case StateType.booked:
        return 'booked';
      case StateType.completed:
        return 'completed';
      case StateType.failed:
        return 'failed';
      case StateType.locked:
        return 'locked';
      case StateType.valid:
        return 'valid';
      case StateType.invalid:
        return 'invalid';
      case StateType.sufficient:
        return 'sufficient';
      case StateType.insufficient:
        return 'insufficient';
      case StateType.duplicate:
        return 'duplicate';
      case StateType.outOfStock:
        return 'out of stock';
      case StateType.paid:
        return 'paid';
      case StateType.unpaid:
        return 'unpaid';
      case StateType.shipped:
        return 'shipped';
      case StateType.delivered:
        return 'delivered';
      case StateType.refunded:
        return 'refunded';
      case StateType.authenticated:
        return 'authenticated';
      case StateType.unauthenticated:
        return 'unauthenticated';
      case StateType.authorized:
        return 'authorized';
      case StateType.unauthorized:
        return 'unauthorized';
      case StateType.approved:
        return 'approved';
      case StateType.denied:
        return 'denied';
      case StateType.abnormal:
        return 'abnormal';
      case StateType.discounted:
        return 'discounted';
      case StateType.rejected:
        return 'rejected';
      case StateType.processed:
        return 'processed';
      case StateType.shared:
        return 'shared';
      case StateType.restricted:
        return 'restricted';
      case StateType.masked:
        return 'masked';
      case StateType.flagged:
        return 'flagged';
      case StateType.deliveredState:
        return 'delivered';
      case StateType.triggered:
        return 'triggered';
      case StateType.accepted:
        return 'accepted';
      case StateType.exhausted:
        return 'exhausted';
      case StateType.accessGranted:
        return 'access granted';
      case StateType.accessDenied:
        return 'access denied';
      case StateType.withinRange:
        return 'within range';
      case StateType.exceeded:
        return 'exceeded';
      case StateType.successful:
        return 'successful';
      case StateType.normal:
        return 'normal';
      case StateType.required:
        return 'required';
      case StateType.created:
        return 'created';
      case StateType.updated:
        return 'updated';
      case StateType.deleted:
        return 'deleted';
      case StateType.scheduled:
        return 'scheduled';
      case StateType.redirected:
        return 'redirected';
    }
  }
}
