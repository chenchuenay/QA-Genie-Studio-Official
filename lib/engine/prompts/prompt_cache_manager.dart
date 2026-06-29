import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/engine/prompts/system_prompt.dart';

class PromptCacheManager {
  const PromptCacheManager._();

  static const String _prefKeyVersion = 'cached_prompt_version';
  static const String _prefKeyPrompt = 'cached_prompt_content';
  static const String _prefKeyTimestamp = 'cached_prompt_timestamp';
  static const int _ttlMillis = 7 * 24 * 60 * 60 * 1000; // 7 days

  static String? _cachedPrompt;
  static String? _cachedVersion;
  static DateTime? _cachedTimestamp;

  static Future<void> warmup() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getString(_prefKeyVersion);
    final storedPrompt = prefs.getString(_prefKeyPrompt);
    final storedTimestamp = prefs.getInt(_prefKeyTimestamp);

    bool isValid = false;
    if (storedVersion != null &&
        storedPrompt != null &&
        storedTimestamp != null) {
      final age = DateTime.now().millisecondsSinceEpoch - storedTimestamp;
      if (age < _ttlMillis && storedVersion == SystemPrompt.version) {
        isValid = true;
        _cachedPrompt = storedPrompt;
        _cachedVersion = storedVersion;
        _cachedTimestamp = DateTime.fromMillisecondsSinceEpoch(storedTimestamp);
      }
    }

    if (!isValid) {
      _cachedPrompt = SystemPrompt.masterPromptFor('Web');
      _cachedVersion = SystemPrompt.version;
      _cachedTimestamp = DateTime.now();
      await prefs.setString(_prefKeyVersion, _cachedVersion!);
      await prefs.setString(_prefKeyPrompt, _cachedPrompt!);
      await prefs.setInt(
        _prefKeyTimestamp,
        _cachedTimestamp!.millisecondsSinceEpoch,
      );
    }
  }

  static String get masterPrompt {
    _cachedPrompt ??= SystemPrompt.masterPromptFor('Web');
    _cachedVersion ??= SystemPrompt.version;
    return _cachedPrompt!;
  }

  static bool get isWarm => _cachedPrompt != null;
  static String get version => _cachedVersion ?? SystemPrompt.version;

  static Future<void> invalidate() async {
    _cachedPrompt = null;
    _cachedVersion = null;
    _cachedTimestamp = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyVersion);
    await prefs.remove(_prefKeyPrompt);
    await prefs.remove(_prefKeyTimestamp);
  }

  static Future<void> refresh() async {
    await invalidate();
    await warmup();
  }
}
