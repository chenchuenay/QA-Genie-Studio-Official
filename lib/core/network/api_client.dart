import 'dart:convert';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:qa_genie/data/models/test_case_model.dart';

class ApiClient {
  static const String _apiKey = "AIzaSyBVj0nQTodCE2TRj_JdhtklItczt_HxKa4";
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent";

  Future<List<TestCaseModel>> generate(String prompt) async {
    final fullPrompt =
        '''
$prompt
CRITICAL: Return ONLY pure JSON array. No code, no functions, no expressions like .repeat(). Only static string values.
''';

    PipelineDebugStore.lastFinalPrompt = fullPrompt;

    print('[AI DEBUG] Model URL: $_baseUrl');
    print('[AI DEBUG] Prompt (first 200 chars): ${fullPrompt.substring(0, 200)}...');
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
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      print('[AI DEBUG] API KEY first 8 chars: ${_apiKey.substring(0, 8)}...');
      print('[AI DEBUG] Response body: ${res.body}');
      throw Exception(res.body);
    }

    final data = jsonDecode(res.body);
    if (data['candidates'] == null || data['candidates'].isEmpty) {
      throw Exception('No candidates returned: ${res.body}');
    }

    String text = data['candidates'][0]['content']['parts'][0]['text'];
    PipelineDebugStore.lastRawResponse = text;

    text = text.replaceAll('```json', '').replaceAll('```', '').trim();
    PipelineDebugStore.lastCleanedResponse = text;
    text = text.replaceAll(RegExp(r'"[^"]*"\.repeat\(\d+\)'), '""');
    text = text
        .split('\n')
        .where(
          (line) => !line.trim().startsWith('//') && !line.contains('.repeat('),
        )
        .join('\n');

    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start == -1 || end == -1) throw Exception("Invalid AI response format");

    final clean = text.substring(start, end + 1);
    PipelineDebugStore.lastCleanedResponse = clean;
    try {
      final List list = jsonDecode(clean);
      print('[AI DEBUG] Raw response text (first 500 chars): ${text.substring(0, text.length > 500 ? 500 : text.length)}');
    print('[AI DEBUG] Parsed ${list.length} test cases successfully.');
    return list
          .map((e) => TestCaseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final preview = clean.length > 300 ? clean.substring(0, 300) : clean;
      throw Exception("Failed to parse AI JSON: $e\nRaw text: $preview...");
    }
  }
}