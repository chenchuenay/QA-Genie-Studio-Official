import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  group('StateType', () {
    test('all enum values have a displayName', () {
      for (final state in StateType.values) {
        expect(state.displayName, isNotEmpty);
      }
    });

    test('displayName returns correct name for each state', () {
      expect(StateType.active.displayName, 'active');
      expect(StateType.inactive.displayName, 'inactive');
      expect(StateType.pending.displayName, 'pending');
      expect(StateType.confirmed.displayName, 'confirmed');
      expect(StateType.cancelled.displayName, 'cancelled');
      expect(StateType.expired.displayName, 'expired');
      expect(StateType.outOfStock.displayName, 'out of stock');
      expect(StateType.authenticated.displayName, 'authenticated');
      expect(StateType.unauthenticated.displayName, 'unauthenticated');
      expect(StateType.authorized.displayName, 'authorized');
      expect(StateType.unauthorized.displayName, 'unauthorized');
      expect(StateType.deliveredState.displayName, 'delivered');
      expect(StateType.accessGranted.displayName, 'access granted');
      expect(StateType.accessDenied.displayName, 'access denied');
      expect(StateType.withinRange.displayName, 'within range');
      expect(StateType.exceeded.displayName, 'exceeded');
      expect(StateType.successful.displayName, 'successful');
      expect(StateType.normal.displayName, 'normal');
      expect(StateType.required.displayName, 'required');
      expect(StateType.created.displayName, 'created');
      expect(StateType.updated.displayName, 'updated');
      expect(StateType.deleted.displayName, 'deleted');
      expect(StateType.scheduled.displayName, 'scheduled');
      expect(StateType.redirected.displayName, 'redirected');
    });

    test('enum values are not empty', () {
      expect(StateType.values.length, greaterThan(0));
    });
  });
}
