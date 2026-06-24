import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/prompts/prompt_composer.dart';

void main() {
  group('PromptComposer', () {
    test('compose returns non-empty result', () {
      final result = PromptComposer.compose(
        module: 'Login',
        feature: 'User Authentication',
        platform: 'WEB',
        skeletons: [
          {'category': 'positive', 'type': 'POSITIVE', 'priority': 'High', 'intent_id': 'valid_login', 'title': 'Verify successful login'}
        ],
        constraints: 'Test with valid credentials',
        domain: 'auth',
      );
      expect(result, isNotEmpty);
    });

    test('compose includes return instruction', () {
      final result = PromptComposer.compose(
        module: 'Login',
        feature: 'User Auth',
        platform: 'WEB',
        skeletons: [],
      );
      expect(result, contains('Return ONLY valid JSON'));
    });

    test('compose includes context block', () {
      final result = PromptComposer.compose(
        module: 'Checkout',
        feature: 'Payment',
        platform: 'Mobile',
        skeletons: [],
      );
      expect(result, contains('=== CONTEXT ==='));
      expect(result, contains('Checkout'));
      expect(result, contains('Payment'));
      expect(result, contains('Mobile'));
    });

    test('compose includes constraints when provided', () {
      final result = PromptComposer.compose(
        module: 'Login',
        feature: 'Auth',
        platform: 'WEB',
        skeletons: [],
        constraints: 'must use MFA',
      );
      expect(result, contains('must use MFA'));
    });

    test('compose omits constraints when empty', () {
      final result = PromptComposer.compose(
        module: 'Login',
        feature: 'Auth',
        platform: 'WEB',
        skeletons: [],
        constraints: '',
      );
      expect(result, contains('=== CONTEXT ==='));
    });

    test('compose includes skeleton plan', () {
      final result = PromptComposer.compose(
        module: 'Login',
        feature: 'Auth',
        platform: 'WEB',
        skeletons: [
          {'category': 'positive', 'type': 'POSITIVE', 'priority': 'High', 'intent_id': 'valid_login', 'title': 'Valid login'}
        ],
      );
      expect(result, contains('=== GENERATION PLAN ==='));
      expect(result, contains('CASE 1'));
      expect(result, contains('positive'));
    });

    test('compose includes JSON contract', () {
      final result = PromptComposer.compose(
        module: 'Login',
        feature: 'Auth',
        platform: 'WEB',
        skeletons: [],
      );
      expect(result, contains('=== JSON CONTRACT ==='));
    });

    test('compose includes final execution rule', () {
      final result = PromptComposer.compose(
        module: 'Login',
        feature: 'Auth',
        platform: 'WEB',
        skeletons: [],
      );
      expect(result, contains('FINAL EXECUTION RULE'));
      expect(result, contains('Return ONLY valid JSON'));
    });

    test('compose uses domain parameter', () {
      final result = PromptComposer.compose(
        module: 'Payment',
        feature: 'Checkout',
        platform: 'API',
        skeletons: [],
        domain: 'commerce',
      );
      expect(result, contains('commerce'));
    });
  });
}
