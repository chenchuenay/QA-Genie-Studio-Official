import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/engine/prompts/prompt_cache_manager.dart';
import 'package:qa_genie/engine/prompts/system_prompt.dart';

void main() {
  group('PromptCacheManager', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PromptCacheManager.invalidate();
    });

    test('isWarm returns false initially', () {
      expect(PromptCacheManager.isWarm, isFalse);
    });

    test('masterPrompt returns system prompt without warmup', () {
      final prompt = PromptCacheManager.masterPrompt;
      expect(prompt, equals(SystemPrompt.masterPromptFor('Web')));
      expect(PromptCacheManager.isWarm, isTrue);
    });

    test('version returns system prompt version', () {
      expect(PromptCacheManager.version, equals(SystemPrompt.version));
    });

    test('warmup caches prompt from SharedPreferences when valid', () async {
      SharedPreferences.setMockInitialValues({
        'cached_prompt_version': SystemPrompt.version,
        'cached_prompt_content': 'Cached prompt content',
        'cached_prompt_timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await PromptCacheManager.warmup();
      expect(PromptCacheManager.isWarm, isTrue);
      expect(PromptCacheManager.masterPrompt, equals('Cached prompt content'));
    });

    test('warmup refreshes prompt when version mismatch', () async {
      SharedPreferences.setMockInitialValues({
        'cached_prompt_version': 'OLD_VERSION',
        'cached_prompt_content': 'Old prompt',
        'cached_prompt_timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await PromptCacheManager.warmup();
      expect(PromptCacheManager.masterPrompt, equals(SystemPrompt.masterPromptFor('Web')));
    });

    test('warmup refreshes prompt when cache expired', () async {
      SharedPreferences.setMockInitialValues({
        'cached_prompt_version': SystemPrompt.version,
        'cached_prompt_content': 'Expired prompt',
        'cached_prompt_timestamp': 1, // very old
      });
      await PromptCacheManager.warmup();
      expect(PromptCacheManager.masterPrompt, equals(SystemPrompt.masterPromptFor('Web')));
    });

    test('invalidate clears the cache', () async {
      PromptCacheManager.masterPrompt; // warm
      expect(PromptCacheManager.isWarm, isTrue);
      await PromptCacheManager.invalidate();
      expect(PromptCacheManager.isWarm, isFalse);
    });

    test('refresh invalidates then warms up', () async {
      PromptCacheManager.masterPrompt; // warm
      expect(PromptCacheManager.isWarm, isTrue);
      await PromptCacheManager.refresh();
      expect(PromptCacheManager.isWarm, isTrue);
      expect(PromptCacheManager.masterPrompt, equals(SystemPrompt.masterPromptFor('Web')));
    });
  });
}
