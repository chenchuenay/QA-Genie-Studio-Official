import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/generators/title_generator.dart';
import 'package:qa_genie/engine/models/scenario.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  group('TitleGenerator', () {
    test('generate returns positive category title', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.create,
        targetState: StateType.active,
        category: 'positive',
      );
      final title = TitleGenerator.generate(scenario, 'Auth');
      expect(title, contains('Create'));
      expect(title, contains('account'));
      expect(title, contains('Auth'));
    });

    test('generate returns negative category title', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.create,
        targetState: StateType.failed,
        category: 'negative',
      );
      final title = TitleGenerator.generate(scenario, 'Auth');
      expect(title, contains('Creating'));
      expect(title, contains('account'));
      expect(title, contains('fails'));
    });

    test('generate returns validation category title', () {
      final scenario = Scenario(
        entity: EntityType.password,
        action: ActionType.reset,
        targetState: StateType.active,
        category: 'validation',
      );
      final title = TitleGenerator.generate(scenario, 'Auth');
      expect(title, contains('validate'));
      expect(title, contains('password'));
      expect(title, contains('reset'));
    });

    test('generate returns security category title', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.authenticated,
        category: 'security',
      );
      final title = TitleGenerator.generate(scenario, 'Auth');
      expect(title, contains('security'));
      expect(title, contains('malicious'));
    });

    test('generate returns boundary category title', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.active,
        category: 'boundary',
      );
      final title = TitleGenerator.generate(scenario, 'Auth');
      expect(title, contains('boundary'));
      expect(title, contains('maximum allowed'));
    });

    test('generate returns session category title', () {
      final scenario = Scenario(
        entity: EntityType.session,
        action: ActionType.refresh,
        targetState: StateType.expired,
        category: 'session',
      );
      final title = TitleGenerator.generate(scenario, 'Auth');
      expect(title, contains('session'));
      expect(title, contains('expired'));
    });

    test('generate returns fallback for unknown category', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.login,
        targetState: StateType.active,
        category: 'unknown',
      );
      final title = TitleGenerator.generate(scenario, 'Auth');
      expect(title.toLowerCase(), contains('login'));
      expect(title, contains('Account'));
      expect(title, contains('Auth'));
    });

    test('generate produces different titles for different actions', () {
      final s1 = Scenario(entity: EntityType.account, action: ActionType.create, targetState: StateType.active, category: 'positive');
      final s2 = Scenario(entity: EntityType.account, action: ActionType.view, targetState: StateType.active, category: 'positive');
      final t1 = TitleGenerator.generate(s1, 'Feat');
      final t2 = TitleGenerator.generate(s2, 'Feat');
      expect(t1, isNot(equals(t2)));
    });

    test('generate handles action with lowercase display name', () {
      final scenario = Scenario(
        entity: EntityType.account,
        action: ActionType.add,
        targetState: StateType.active,
        category: 'positive',
      );
      final title = TitleGenerator.generate(scenario, 'Cart');
      expect(title, contains('Add'));
      expect(title, contains('account'));
    });
  });
}
