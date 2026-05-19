import 'dart:async';
import 'dart:convert';
import 'ai_provider.dart';
import 'package:http/http.dart' as http;
import 'package:qa_genie/engine/pipeline/system_prompt.dart';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';

class GroqProvider implements AiProvider {
  final String apiKey;

  GroqProvider({
    this.apiKey = const String.fromEnvironment(
      'GROQ_API_KEY',
      defaultValue: '',
    ),
  });

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static const _model = 'llama-3.3-70b-versatile';

  @override
  Future<String> generate(String prompt) async {
    PipelineDebugStore.lastProvider = 'groq';

    if (apiKey.trim().isEmpty) {
      throw Exception('Missing GROQ_API_KEY');
    }

    final payload = {
      'model': _model,

      // STRICT CHAT FORMAT
      'messages': [
        {'role': 'system', 'content': SystemPrompt.systemInstruction},
        {'role': 'user', 'content': prompt},
      ],

      // STABILITY
      'temperature': 0.15,
      'top_p': 0.85,

      // OUTPUT CONTROL
      'frequency_penalty': 0.15,
      'presence_penalty': 0.0,

      // IMPORTANT FOR JSON RELIABILITY
      'stream': false,

      // TOKEN BUDGET
      'max_completion_tokens': 12000,
    };

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 90));

    PipelineDebugStore.lastRawResponse = response.body;

    if (response.statusCode != 200) {
      throw Exception('Groq error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    final content =
        decoded['choices']?[0]?['message']?['content']?.toString() ?? '';

    if (content.trim().isEmpty) {
      throw Exception('Empty Groq response');
    }

    return _sanitize(content);
  }

  String _sanitize(String value) {
    var cleaned = value.trim();

    cleaned = cleaned
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .replaceAll('<think>', '')
        .replaceAll('</think>', '')
        .replaceAll('<thinking>', '')
        .replaceAll('</thinking>', '');

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^\s*Here(?: is| are).*?:', caseSensitive: false),
      (_) => '',
    );

    cleaned = cleaned.trim();

    final arrayStart = cleaned.indexOf('[');
    final arrayEnd = cleaned.lastIndexOf(']');

    if (arrayStart != -1 && arrayEnd != -1 && arrayEnd > arrayStart) {
      cleaned = cleaned.substring(arrayStart, arrayEnd + 1);
    }

    return cleaned.trim();
  }
}
