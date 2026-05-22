import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiCacheService {
  static String? _cacheName;
  static Future<String?>? _inflight;

  static Future<String?> ensureCache({
    required String apiKey,
    required String systemPrompt,
    String model = 'models/gemini-2.5-flash',
  }) async {
    if (_cacheName != null) {
      return _cacheName;
    }

    final existing = _inflight;
    if (existing != null) return existing;

    _inflight = _createCache(
      apiKey: apiKey,
      systemPrompt: systemPrompt,
      model: model,
    );

    try {
      return await _inflight;
    } finally {
      _inflight = null;
    }
  }

  static Future<String?> _createCache({
    required String apiKey,
    required String systemPrompt,
    required String model,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/cachedContents?key=$apiKey',
    );
    final body = {
      'model': model,
      'displayName': 'qa_genie_prompt_cache',
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': systemPrompt},
          ],
        },
      ],
      'ttl': '3600s',
    };
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      _cacheName = json['name'];
      return _cacheName;
    }
    return null;
  }

  static void clearCache() {
    _cacheName = null;
    _inflight = null;
  }
}
