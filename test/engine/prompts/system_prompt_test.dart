import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/prompts/system_prompt.dart';

void main() {
  group('SystemPrompt', () {
    test('version is not empty', () {
      expect(SystemPrompt.version, isNotEmpty);
    });

    test('masterPromptFor is not empty', () {
      expect(SystemPrompt.masterPromptFor('Web'), isNotEmpty);
    });

    test('masterPromptFor contains QA Genie', () {
      expect(SystemPrompt.masterPromptFor('Web'), contains('QA Genie'));
    });

    test('masterPromptFor contains quality guidelines', () {
      expect(SystemPrompt.masterPromptFor('Web'), contains('QUALITY GUIDELINES'));
    });

    test('masterPromptFor only includes the selected platform guideline', () {
      expect(SystemPrompt.masterPromptFor('Web'), contains('WEB'));
      expect(SystemPrompt.masterPromptFor('Web'), isNot(contains('MOBILE')));
      expect(SystemPrompt.masterPromptFor('Web'), isNot(contains('API')));

      expect(SystemPrompt.masterPromptFor('Mobile'), contains('MOBILE'));
      expect(SystemPrompt.masterPromptFor('Mobile'), isNot(contains('WEB')));
      expect(SystemPrompt.masterPromptFor('Mobile'), isNot(contains('API')));

      expect(SystemPrompt.masterPromptFor('API'), contains('API'));
      expect(SystemPrompt.masterPromptFor('API'), isNot(contains('WEB')));
      expect(SystemPrompt.masterPromptFor('API'), isNot(contains('MOBILE')));
    });
  });
}
