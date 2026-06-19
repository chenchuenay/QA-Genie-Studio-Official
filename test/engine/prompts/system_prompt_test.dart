import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/prompts/system_prompt.dart';

void main() {
  group('SystemPrompt', () {
    test('version is not empty', () {
      expect(SystemPrompt.version, isNotEmpty);
    });

    test('masterPrompt is not empty', () {
      expect(SystemPrompt.masterPrompt, isNotEmpty);
    });

    test('masterPrompt contains QA Genie', () {
      expect(SystemPrompt.masterPrompt, contains('QA Genie'));
    });

    test('masterPrompt contains quality guidelines', () {
      expect(SystemPrompt.masterPrompt, contains('QUALITY GUIDELINES'));
    });

    test('masterPrompt mentions platform types', () {
      expect(SystemPrompt.masterPrompt, contains('WEB'));
      expect(SystemPrompt.masterPrompt, contains('MOBILE'));
      expect(SystemPrompt.masterPrompt, contains('API'));
    });
  });
}
