import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/ontology/actions.dart';

void main() {
  group('ActionType', () {
    test('all enum values have a displayName', () {
      for (final action in ActionType.values) {
        expect(action.displayName, isNotEmpty);
      }
    });

    test('displayName returns correct name for each action', () {
      expect(ActionType.create.displayName, 'create');
      expect(ActionType.view.displayName, 'view');
      expect(ActionType.update.displayName, 'update');
      expect(ActionType.delete.displayName, 'delete');
      expect(ActionType.cancel.displayName, 'cancel');
      expect(ActionType.reschedule.displayName, 'reschedule');
      expect(ActionType.authenticate.displayName, 'authenticate');
      expect(ActionType.login.displayName, 'login');
      expect(ActionType.logout.displayName, 'logout');
      expect(ActionType.refresh.displayName, 'refresh');
      expect(ActionType.verify.displayName, 'verify');
      expect(ActionType.authorize.displayName, 'authorize');
      expect(ActionType.reset.displayName, 'reset');
      expect(ActionType.validate.displayName, 'validate');
      expect(ActionType.reject.displayName, 'reject');
      expect(ActionType.block.displayName, 'block');
      expect(ActionType.updateQuantity.displayName, 'update quantity');
      expect(ActionType.webhookTrigger.displayName, 'trigger webhook');
      expect(ActionType.retryOp.displayName, 'retry');
      expect(ActionType.sendReminder.displayName, 'send reminder');
      expect(ActionType.accessGranted.displayName, 'access granted');
      expect(ActionType.accessDenied.displayName, 'access denied');
      expect(ActionType.requestRefill.displayName, 'request refill');
      expect(ActionType.assign.displayName, 'assign');
      expect(ActionType.blockOp.displayName, 'block');
      expect(ActionType.rejectOp.displayName, 'reject');
    });

    test('enum values are not empty', () {
      expect(ActionType.values.length, greaterThan(0));
    });
  });
}
