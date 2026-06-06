import 'package:qa_genie/engine/prompts/system_prompt.dart';

class PromptCacheManager {
  const PromptCacheManager._();

  static String? _cachedPrompt;
  static String? _cachedVersion;

  static void warmup() {
    if (_cachedPrompt != null && _cachedVersion == SystemPrompt.version) {
      return;
    }
    _cachedPrompt = SystemPrompt.masterPrompt;
    _cachedVersion = SystemPrompt.version;
  }

  static String get masterPrompt {
    warmup();
    return _cachedPrompt!;
  }

  static bool get isWarm => _cachedPrompt != null;
  static String get version => _cachedVersion ?? 'UNKNOWN';

  static void invalidate() {
    _cachedPrompt = null;
    _cachedVersion = null;
  }

  static void refresh() {
    invalidate();
    warmup();
  }
}
