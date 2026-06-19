import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/planners/prompt_planner.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';

void main() {
  group('PromptPlanner', () {
    group('generateSkeletons', () {
      test('generates correct number of skeletons', () {
        final planner = PromptPlanner(
          module: 'Auth',
          feature: 'Login',
          platform: 'API',
          mode: GenerationMode.core,
          count: 4,
          domain: 'identity',
          constraints: '',
        );
        final skeletons = planner.generateSkeletons();
        expect(skeletons.length, 4);
      });

      test('each skeleton has required keys', () {
        final planner = PromptPlanner(
          module: 'Auth',
          feature: 'Login',
          platform: 'API',
          mode: GenerationMode.core,
          count: 1,
          domain: 'identity',
        );
        final skeletons = planner.generateSkeletons();
        final s = skeletons.first;
        expect(s, containsPair('intent_id', 'positive_1'));
        expect(s, containsPair('category', 'positive'));
        expect(s, containsPair('module', 'Auth'));
        expect(s, containsPair('feature', 'Login'));
        expect(s, containsPair('platform', 'API'));
        expect(s, containsPair('constraints', ''));
        expect(s, containsPair('type', 'POSITIVE'));
      });

      test('assigns Low priority for positive category', () {
        final planner = PromptPlanner(
          module: 'M', feature: 'F', platform: 'API', mode: GenerationMode.core, count: 4, constraints: '',
        );
        final skeletons = planner.generateSkeletons();
        for (final s in skeletons) {
          if (s['category'] == 'positive') {
            expect(s['priority'], 'Low');
          }
        }
      });

      test('assigns Medium priority for negative and validation categories', () {
        final planner = PromptPlanner(
          module: 'M', feature: 'F', platform: 'API', mode: GenerationMode.core, count: 8, constraints: '',
        );
        final skeletons = planner.generateSkeletons();
        for (final s in skeletons) {
          if (s['category'] == 'negative') {
            expect(s['priority'], 'Medium');
          }
        }
      });

      test('assigns High priority for security category', () {
        final planner = PromptPlanner(
          module: 'M', feature: 'F', platform: 'API', mode: GenerationMode.core, count: 3, constraints: 'only security',
        );
        final skeletons = planner.generateSkeletons();
        for (final s in skeletons) {
          expect(s['priority'], 'High');
        }
      });

      test('assigns High priority for session category', () {
        final planner = PromptPlanner(
          module: 'M', feature: 'F', platform: 'API', mode: GenerationMode.core, count: 2, constraints: 'session',
        );
        final skeletons = planner.generateSkeletons();
        for (final s in skeletons) {
          expect(s['priority'], 'High');
        }
      });

      test('generates unique intent IDs', () {
        final planner = PromptPlanner(
          module: 'M', feature: 'F', platform: 'API', mode: GenerationMode.core, count: 8, constraints: '',
        );
        final skeletons = planner.generateSkeletons();
        final ids = skeletons.map((s) => s['intent_id'] as String).toSet();
        expect(ids.length, skeletons.length);
      });

      test('generates correct titles for each category', () {
        final planner = PromptPlanner(
          module: 'M', feature: 'Login', platform: 'API', mode: GenerationMode.core, count: 8, constraints: '',
        );
        final skeletons = planner.generateSkeletons();
        for (final s in skeletons) {
          final cat = s['category'] as String;
          final title = s['title'] as String;
          switch (cat) {
            case 'positive':
              expect(title, 'Login - positive scenario');
            case 'negative':
              expect(title, 'Login - negative scenario');
            case 'boundary':
              expect(title, 'Login - boundary test');
            case 'validation':
              expect(title, 'Login - validation test');
            case 'security':
              expect(title, 'Login - security test');
            default:
              expect(title, 'Login test');
          }
        }
      });

      test('uses default category title for unknown category', () {
        final planner = PromptPlanner(
          module: 'M', feature: 'F', platform: 'API', mode: GenerationMode.core, count: 0, constraints: '',
        );
        final skeletons = planner.generateSkeletons();
        expect(skeletons, isEmpty);
      });

      test('passes domain and constraints to each skeleton', () {
        final planner = PromptPlanner(
          module: 'M', feature: 'F', platform: 'API', mode: GenerationMode.core, count: 3, domain: 'identity', constraints: 'oauth',
        );
        final skeletons = planner.generateSkeletons();
        for (final s in skeletons) {
          expect(s['constraints'], 'oauth');
        }
      });
    });

    test('generateSkeletons with totalCount 0 returns empty list', () {
      final planner = PromptPlanner(
        module: 'M', feature: 'F', platform: 'API', mode: GenerationMode.core, count: 0,
      );
      expect(planner.generateSkeletons(), isEmpty);
    });
  });
}
