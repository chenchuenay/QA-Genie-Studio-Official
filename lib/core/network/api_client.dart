import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:qa_app/data/models/test_case_model.dart';

class ApiClient {
  static const String _apiKey = "AIzaSyAmhLTG3qnjtXF_GRia1y3WMIIlbooq8o0";
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent";

  Future<List<TestCaseModel>> generate(String prompt) async {
    final fullPrompt =
        '''
$prompt
CRITICAL: Return ONLY pure JSON array. No code, no functions, no expressions like .repeat(). Only static string values.
''';

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

    if (res.statusCode != 200) throw Exception(res.body);

    final data = jsonDecode(res.body);
    String text = data['candidates'][0]['content']['parts'][0]['text'];

    text = text.replaceAll('```json', '').replaceAll('```', '').trim();
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
    try {
      final List list = jsonDecode(clean);
      return list
          .map((e) => TestCaseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final preview = clean.length > 300 ? clean.substring(0, 300) : clean;
      throw Exception("Failed to parse AI JSON: $e\nRaw text: $preview...");
    }
  }
}
