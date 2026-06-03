import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qa_genie/core/error/exceptions.dart';
import 'package:qa_genie/core/network/connectivity_service.dart';
import 'package:qa_genie/engine/forensics/pipeline_observer.dart';
// ============================================================
// FILE: lib/core/network/api_client.dart
// ============================================================




/// ===============================================================
///
/// API CLIENT
///
/// PURPOSE:
/// - Centralized AI provider communication
/// - Environment-safe API handling
/// - Request timeout protection
/// - Token/cost containment
/// - Deterministic request structure
///
/// IMPORTANT:
/// API KEYS MUST NEVER EXIST IN SOURCE CODE.
///
/// USE:
/// .env
///
/// Example:
/// GEMINI_API_KEY=xxxxx
/// GEMINI_BASE_URL=https://generativelanguage.googleapis.com
///
/// ===============================================================
class ApiClient {
  ApiClient._();

  static const Duration _timeout = Duration(seconds: 45);

  // ============================================================
  // ENV
  // ============================================================

  static String get _apiKey {
    final value = dotenv.env['GEMINI_API_KEY'];
    print('API_CLIENT_DEBUG: Loaded API Key (length: ${value?.length})');

    if (value == null || value.trim().isEmpty) {
      PipelineForensics.instance.onTraceEvent('\n[AI ERROR]\nerror=Missing GEMINI_API_KEY in .env');
      throw const ConfigurationException('Missing GEMINI_API_KEY in .env');
    }

    return value;
  }

  static String get _baseUrl {
    final value = dotenv.env['GEMINI_BASE_URL'];
    print('API_CLIENT_DEBUG: Loaded Base URL: $value');

    if (value == null || value.trim().isEmpty) {
      throw const ConfigurationException('Missing GEMINI_BASE_URL in .env');
    }

    return value;
  }

  static String get _model {
    return dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash-lite';
  }

  // ============================================================
  // GENERATE
  // ============================================================

  static Future<String> generate({
    required String prompt,
    String? traceId,
  }) async {
    final online = await ConnectivityService.checkNow();

    if (!online) {
      throw const NetworkException('No internet connection.');
    }

    final url = '$_baseUrl/v1beta/models/$_model:generateContent?key=$_apiKey';
    print('API_CLIENT_DEBUG: Sending request to $url');

    final uri = Uri.parse(url);

    PipelineForensics.instance.onTraceEvent('\n[AI NETWORK]\nrequestSent=true');

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],

      // ========================================================
      // TOKEN CONTROL
      // ========================================================
      'generationConfig': {
        'temperature': 0.25,
        'topP': 0.8,
        'topK': 32,
        'maxOutputTokens': 8192,
      },

      // ========================================================
      // SAFETY
      // ========================================================
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    };

    try {
      final stopwatch = Stopwatch()..start();
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (traceId != null) 'X-Trace-ID': traceId,
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      stopwatch.stop();

      PipelineForensics.instance.onTraceEvent('status=${response.statusCode}\nlatencyMs=${stopwatch.elapsedMilliseconds}');

      PipelineForensics.instance.onTraceEvent('\n[AI RAW RESPONSE]\nlength=${response.body.length}');
      PipelineForensics.instance.onTraceEvent('first1000=${response.body.length > 1000 ? response.body.substring(0, 1000) : response.body}');
      PipelineForensics.instance.onTraceEvent('last1000=${response.body.length > 1000 ? response.body.substring(response.body.length - 1000) : response.body}');

      print('API_CLIENT_DEBUG: Response status: ${response.statusCode}');
      print('API_CLIENT_DEBUG: Response body: ${response.body}');

      return _handleResponse(response);
    } on TimeoutException {
      throw const NetworkException('AI request timeout.');
    } catch (e) {
      print('API_CLIENT_DEBUG: Exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // RESPONSE
  // ============================================================

  static String _handleResponse(http.Response response) {
    print('FORENSIC: HTTP_STATUS: ${response.statusCode}');
    print('FORENSIC: RAW_RESPONSE_LENGTH: ${response.body.length}');
    print(
        'FORENSIC: FIRST_500_CHARS_OF_RESPONSE: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');

    if (response.statusCode >= 500) {
      print('API_CLIENT_DEBUG: Server Error: ${response.statusCode}, Body: ${response.body}');
      throw const ServerException('AI provider unavailable.');
    }

    if (response.statusCode == 429) {
      print('API_CLIENT_DEBUG: Rate Limit: ${response.statusCode}');
      throw const RateLimitException('Rate limit exceeded.');
    }

    if (response.statusCode >= 400) {
      print('API_CLIENT_DEBUG: Client Error: ${response.statusCode}, Body: ${response.body}');
      throw ApiException('AI request failed (${response.statusCode})');
    }

    try {
      final decoded = jsonDecode(response.body);
      final candidates = decoded['candidates'] as List?;
      print('FORENSIC: CANDIDATE_COUNT: ${candidates?.length ?? 0}');

      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']['parts'] as List?;
        print('FORENSIC: TEXT_PART_COUNT: ${parts?.length ?? 0}');
      }

      final text =
          decoded['candidates'][0]['content']['parts'][0]['text'] as String;

      print('FORENSIC: FINAL_EXTRACTED_TEXT_LENGTH: ${text.length}');

      if (text.trim().isEmpty) {
        throw const ApiException('Empty AI response.');
      }

      return text;
    } catch (e) {
      print('API_CLIENT_DEBUG: JSON Decoding Error: $e, Body: ${response.body}');
      throw const ParsingException('Malformed AI response.');
    }
  }

  // ============================================================
  // HEALTH
  // ============================================================

  static Future<bool> healthCheck() async {
    try {
      final result = await generate(prompt: 'ping');

      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
