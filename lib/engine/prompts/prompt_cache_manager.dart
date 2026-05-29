import 'package:qa_genie/engine/prompts/system_prompt.dart';
// ============================================================

// FILE: lib/core/prompts/prompt_cache_manager.dart

// ============================================================

class PromptCacheManager {
  const PromptCacheManager._();

  // ==========================================================

  // STATIC CACHE

  // ==========================================================

  static String? _cachedPrompt;

  static String? _cachedVersion;

  // ==========================================================

  // INITIALIZE CACHE

  // ==========================================================

  static void warmup() {
    if (_cachedPrompt != null && _cachedVersion == SystemPrompt.version) {
      return;
    }

    _cachedPrompt = SystemPrompt.masterPrompt;

    _cachedVersion = SystemPrompt.version;
  }

  // ==========================================================

  // ACCESS CACHED PROMPT

  // ==========================================================

  static String get masterPrompt {
    warmup();

    return _cachedPrompt!;
  }

  // ==========================================================

  // CACHE HEALTH

  // ==========================================================

  static bool get isWarm => _cachedPrompt != null;

  static String get version => _cachedVersion ?? 'UNKNOWN';

  // ==========================================================

  // INVALIDATE CACHE

  // ==========================================================

  static void invalidate() {
    _cachedPrompt = null;

    _cachedVersion = null;
  }

  // ==========================================================

  // FORCE REFRESH

  // ==========================================================

  static void refresh() {
    invalidate();

    warmup();
  }
}
