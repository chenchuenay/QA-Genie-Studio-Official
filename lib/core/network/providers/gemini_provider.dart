import 'dart:async';
import 'dart:convert';
import 'ai_provider.dart';
import 'package:http/http.dart' as http;
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';

class GeminiProvider implements AiProvider {
  static const String _apiKey = "AIzaSyBVj0nQTodCE2TRj_JdhtklItczt_HxKa4";
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

  @override
  Future<String> generate(String prompt) async {
    final fullPrompt =
        '''
$prompt

CRITICAL:

Return ONLY a pure JSON array.

No markdown.

No explanations.

No <think>.

No code fences.

No comments.

No JavaScript expressions such as "a".repeat(256). Use literal JSON strings only.

''';

    PipelineDebugStore.lastFinalPrompt = fullPrompt;

    final res = await http
        .post(
          Uri.parse(_baseUrl),

          headers: {
            "Content-Type": "application/json",

            "X-goog-api-key": _apiKey,
          },

          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": fullPrompt},
                ],
              },
            ],

            "generationConfig": {
              "temperature": 0.4,

              "topK": 32,

              "topP": 1,

              "maxOutputTokens": 8192,
            },
          }),
        )
        .timeout(const Duration(seconds: 45));

    PipelineDebugStore.lastRawResponse =
        'STATUS: ${res.statusCode}\nBODY:\n${res.body}';

    if (res.statusCode != 200) {
      throw Exception('Gemini HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body);

    final candidates = data['candidates'];

    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates');
    }

    final content = candidates[0]['content'];

    if (content == null) {
      throw Exception('Gemini content missing');
    }

    final parts = content['parts'];

    if (parts == null || parts.isEmpty) {
      throw Exception('Gemini parts missing');
    }

    final text = parts[0]['text'];

    if (text == null || text.toString().trim().isEmpty) {
      throw Exception('Gemini returned empty text');
    }

    return text.toString().trim();
  }
}
