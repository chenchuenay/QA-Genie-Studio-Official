import 'dart:async';
import 'dart:convert';
import 'package:qa_genie/core/network/providers/gemini_schema.dart';
import 'package:qa_genie/core/network/providers/gemini_cache_service.dart';
import 'package:qa_genie/core/network/providers/ai_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qa_genie/core/validators/structural_case_validator.dart';
import 'package:qa_genie/engine/recovery/object_boundary_extractor.dart';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';
import 'package:qa_genie/core/logging/telemetry_collector.dart';
import 'package:qa_genie/core/network/providers/api_client.dart';
import 'package:qa_genie/data/datasources/remote/generation_api.dart';
import 'package:qa_genie/core/prompts/system_prompt.dart';

class GeminiProvider implements AiProvider {
  late final GenerationApi _api;
  late final TelemetryCollector _telemetry;
  final String apiKey;

  GeminiProvider({String? apiKey})
    : apiKey =
          apiKey ??
          dotenv.env['GEMINI_API_KEY'] ??
          const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '') {
    _api = GenerationApi(ApiClient(this));
    _telemetry = TelemetryCollector();
  }

  static const _model = 'gemini-2.5-flash-lite';

  @override
  Future<String> generate(String prompt, {int? maxTokens}) async {
    PipelineDebugStore.lastProvider = 'gemini';
    final cleanedKey = apiKey.trim();
    if (cleanedKey.isEmpty) throw Exception('Missing GEMINI_API_KEY');

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$cleanedKey',
    );

    final actualMaxTokens = maxTokens ?? 2600;
    
    final cacheName = await GeminiCacheService.ensureCache(
      apiKey: cleanedKey,
      systemPrompt: SystemPrompt.systemInstruction,
      model: _model,
    );

    _recordTokenForensics(
      prompt: prompt,
      systemPrompt: SystemPrompt.systemInstruction,
      cacheActive: cacheName != null,
    );

    final payload = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'topP': 0.8,
        'candidateCount': 1,
        'maxOutputTokens': actualMaxTokens,
        'responseMimeType': 'application/json',
        'responseSchema': qaGenieResponseSchema,
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

    PipelineDebugStore.schemaConstrained = true;
    return await _singleShotRequest(uri: uri, payload: payload);
  }

  Future<String> _singleShotRequest({
    required Uri uri,
    required Map<String, dynamic> payload,
  }) async {
    final payloadJson = jsonEncode(payload);
    PipelineDebugStore.lastRawProviderPayload = payloadJson;
    PipelineDebugStore.lastTimestamp = DateTime.now().toIso8601String();
    print('RAW PAYLOAD: $payloadJson');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payloadJson,
    );
    
    final body = response.body;
    PipelineDebugStore.lastFullRawAiResponse = body;
    PipelineDebugStore.lastRawProviderResponse = body;
    print('RAW RESPONSE: $body');
    print('RAW RESPONSE LENGTH: ${body.length}');
    
    PipelineDebugStore.providerRequestSucceeded = response.statusCode == 200;
    PipelineDebugStore.providerHttpStatus = response.statusCode;

    if (response.statusCode != 200) {
      throw Exception('Gemini error ${response.statusCode}: $body');
    }
    
    final decoded = jsonDecode(body);
    final text = decoded['candidates'][0]['content']['parts'][0]['text'].toString();
    
    PipelineDebugStore.rawOpenBrackets = '['.allMatches(text).length;
    PipelineDebugStore.rawCloseBrackets = ']'.allMatches(text).length;
    PipelineDebugStore.rawTailSnapshot = text.length > 200
        ? text.substring(text.length - 200)
        : text;

    final recovered = ObjectBoundaryExtractor.extractSafeObjects(text);
    PipelineDebugStore.recoveredCount = recovered.length;
    PipelineDebugStore.truncatedTailLength = (text.length > 200) ? text.length - 200 : 0;
    
    final validCases = <Map<String, dynamic>>[];
    for (final obj in recovered) {
      try {
        final decoded = jsonDecode(obj);
        if (StructuralCaseValidator.isValid(decoded)) {
          validCases.add(decoded);
        }
      } catch (_) {}
    }
    PipelineDebugStore.safeObjectCount = validCases.length;
    
    print('RAW TEXT LENGTH: ${text.length}');
    
    final trimmed = text.trim();
    final jsonStartOk = trimmed.startsWith('[');
    final jsonEndOk = trimmed.endsWith(']');
    
    print('JSON START OK: $jsonStartOk');
    print('JSON END OK: $jsonEndOk');

    if (!jsonEndOk) {
      throw Exception('JSON validation failed: Output did not end with ]');
    }

    if (text.isNotEmpty) {
      PipelineDebugStore.providerReturnedContent = true;
    }
    return trimmed;
  }


  void _recordTokenForensics({
    required String prompt,
    required String systemPrompt,
    required bool cacheActive,
  }) {
    final promptTokens = _estimateTokens(prompt);
    final systemTokens = _estimateTokens(systemPrompt);
    PipelineDebugStore.estimatedInputTokens = cacheActive
        ? promptTokens
        : promptTokens + systemTokens;
    PipelineDebugStore.estimatedSavedTokens = cacheActive ? systemTokens : 0;

    if (cacheActive) {
      print('CACHE ACTIVE');
      print('Saved Tokens: ${PipelineDebugStore.estimatedSavedTokens}');
    }
  }

  int _estimateTokens(String value) {
    if (value.trim().isEmpty) return 0;
    return (value.length / 4).ceil();
  }
  }

