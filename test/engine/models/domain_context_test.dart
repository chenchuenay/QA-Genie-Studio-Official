import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/ontology/states.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/models/domain_context.dart';

void main() {
  group('DomainContext', () {
    test('can be created with all fields', () {
      final context = DomainContext(
        id: 'identity',
        displayName: 'Identity',
        entities: {EntityType.user, EntityType.account},
        actions: {ActionType.login, ActionType.logout},
        states: {StateType.active, StateType.inactive},
      );
      expect(context.id, 'identity');
      expect(context.displayName, 'Identity');
      expect(context.entities, {EntityType.user, EntityType.account});
      expect(context.actions, {ActionType.login, ActionType.logout});
      expect(context.states, {StateType.active, StateType.inactive});
    });

    test('can be created with empty sets', () {
      final context = DomainContext(
        id: 'empty',
        displayName: 'Empty',
        entities: {},
        actions: {},
        states: {},
      );
      expect(context.entities, isEmpty);
      expect(context.actions, isEmpty);
      expect(context.states, isEmpty);
    });

    test('DomainContext is const', () {
      const context = DomainContext(
        id: 'test',
        displayName: 'Test',
        entities: {},
        actions: {},
        states: {},
      );
      expect(context.id, 'test');
    });
  });
}
