enum ActionType {
  // Core CRUD
  create,
  view,
  update,
  delete,
  cancel,
  reschedule,

  // Authentication & session
  authenticate,
  login,
  logout,
  refresh,
  verify,
  authorize,
  reset,
  validate,
  reject,
  block,

  // Commerce
  add,
  remove,
  updateQuantity,
  apply,
  redeem,
  checkout,
  pay,
  confirm,
  ship,
  generate,
  initiate,
  calculate,

  // Transaction
  transfer,
  deposit,
  withdraw,
  schedule,
  execute,

  // Communication / integration
  send,
  receive,
  call,
  webhookTrigger,
  trigger,
  deliver,
  retryOp,

  // Scheduling
  join,
  book,
  sendReminder,

  // Records
  accessGranted,
  accessDenied,
  requestRefill,
  flag,
  mask,
  share,
  restrict,

  // NEW
  assign, // for role assignment
  blockOp,
  rejectOp,
}

extension ActionTypeExtension on ActionType {
  String get displayName {
    switch (this) {
      case ActionType.create:
        return 'create';
      case ActionType.view:
        return 'view';
      case ActionType.update:
        return 'update';
      case ActionType.delete:
        return 'delete';
      case ActionType.cancel:
        return 'cancel';
      case ActionType.reschedule:
        return 'reschedule';
      case ActionType.authenticate:
        return 'authenticate';
      case ActionType.login:
        return 'login';
      case ActionType.logout:
        return 'logout';
      case ActionType.refresh:
        return 'refresh';
      case ActionType.verify:
        return 'verify';
      case ActionType.authorize:
        return 'authorize';
      case ActionType.reset:
        return 'reset';
      case ActionType.validate:
        return 'validate';
      case ActionType.reject:
        return 'reject';
      case ActionType.block:
        return 'block';
      case ActionType.add:
        return 'add';
      case ActionType.remove:
        return 'remove';
      case ActionType.updateQuantity:
        return 'update quantity';
      case ActionType.apply:
        return 'apply';
      case ActionType.redeem:
        return 'redeem';
      case ActionType.checkout:
        return 'checkout';
      case ActionType.pay:
        return 'pay';
      case ActionType.confirm:
        return 'confirm';
      case ActionType.ship:
        return 'ship';
      case ActionType.generate:
        return 'generate';
      case ActionType.initiate:
        return 'initiate';
      case ActionType.calculate:
        return 'calculate';
      case ActionType.transfer:
        return 'transfer';
      case ActionType.deposit:
        return 'deposit';
      case ActionType.withdraw:
        return 'withdraw';
      case ActionType.schedule:
        return 'schedule';
      case ActionType.execute:
        return 'execute';
      case ActionType.send:
        return 'send';
      case ActionType.receive:
        return 'receive';
      case ActionType.call:
        return 'call';
      case ActionType.webhookTrigger:
        return 'trigger webhook';
      case ActionType.trigger:
        return 'trigger';
      case ActionType.deliver:
        return 'deliver';
      case ActionType.retryOp:
        return 'retry';
      case ActionType.join:
        return 'join';
      case ActionType.book:
        return 'book';
      case ActionType.sendReminder:
        return 'send reminder';
      case ActionType.accessGranted:
        return 'access granted';
      case ActionType.accessDenied:
        return 'access denied';
      case ActionType.requestRefill:
        return 'request refill';
      case ActionType.flag:
        return 'flag';
      case ActionType.mask:
        return 'mask';
      case ActionType.share:
        return 'share';
      case ActionType.restrict:
        return 'restrict';
      case ActionType.assign:
        return 'assign';
      case ActionType.blockOp:
        return 'block';
      case ActionType.rejectOp:
        return 'reject';
    }
  }
}
