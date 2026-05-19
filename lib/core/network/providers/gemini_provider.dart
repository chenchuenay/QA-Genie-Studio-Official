import 'dart:async';
import 'dart:convert';
import 'ai_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qa_genie/engine/pipeline/system_prompt.dart';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';

class GeminiProvider implements AiProvider {
  final String apiKey;

  GeminiProvider({String? apiKey})
    : apiKey =
          apiKey ??
          dotenv.env['GEMINI_API_KEY'] ??
          const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static const _model = 'gemini-2.5-flash';

  @override
  Future<String> generate(String prompt) async {
    PipelineDebugStore.lastProvider = 'gemini';

    final cleanedKey = apiKey.trim();

    if (cleanedKey.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY');
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$cleanedKey',
    );

    final payload = {
      'system_instruction': {
        'parts': [
          {'text': SystemPrompt.systemInstruction},
        ],
      },

      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],

      'generationConfig': {
        'temperature': 0.2,
        'topP': 0.9,
        'candidateCount': 1,
        'maxOutputTokens': 8192,

        // IMPORTANT FOR JSON STABILITY
        'responseMimeType': 'application/json',
      },

      'safetySettings': [
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_NONE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE',
        },
      ],
    };

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 120));

    PipelineDebugStore.lastRawResponse = response.body;

    if (response.statusCode != 200) {
      throw Exception('Gemini error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    final text =
        decoded['candidates']?[0]?['content']?['parts']?[0]?['text']
            ?.toString() ??
        '';

    if (text.trim().isEmpty) {
      throw Exception('Empty Gemini response');
    }

    return _sanitize(text);
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
