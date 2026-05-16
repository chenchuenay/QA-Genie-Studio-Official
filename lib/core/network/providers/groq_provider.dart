import 'dart:async';
import 'dart:convert';
import 'ai_provider.dart';
import 'package:http/http.dart' as http;
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';

class GroqProvider implements AiProvider {
  final String apiKey;
  GroqProvider({
    this.apiKey = const String.fromEnvironment(
      'GROQ_API_KEY',
      defaultValue: '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',
    ),
  });

  @override
  Future<String> generate(String prompt) async {
    PipelineDebugStore.lastProvider = 'groq';
    final response = await http
        .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'llama-3.3-70b-versatile',
            'messages': [
              {
                'role': 'system',
                'content':
                    "You are a senior QA test case generator for a canonical export schema. Return ONLY a pure JSON array. No markdown. No explanations. No <think> tags. No JavaScript expressions.",
              },
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.4,
          }),
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200)
      throw Exception('Groq error: ${response.body}');
    final data = jsonDecode(response.body);
    final content = data['choices']?[0]?['message']?['content'] ?? '';
    if (content.isEmpty) throw Exception('Empty Groq response');
    return content;
  }
}
