import 'dart:async';
import 'dart:convert';
import 'ai_provider.dart';
import 'package:http/http.dart' as http;
import 'package:qa_genie/core/prompts/system_prompt.dart';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qa_genie/engine/recovery/streaming_json_recovery.dart';

class GroqProvider implements AiProvider {
  final String apiKey;

  GroqProvider({String? apiKey})
    : apiKey =
          apiKey ??
          dotenv.env['GROQ_API_KEY'] ??
          const String.fromEnvironment('GROQ_API_KEY', defaultValue: '');

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static const _model = 'llama-3.3-70b-versatile';

  @override
  Future<String> generate(String prompt, {int? maxTokens}) async {
    PipelineDebugStore.lastProvider = 'groq';

    if (apiKey.trim().isEmpty) {
      throw Exception('Missing GROQ_API_KEY');
    }

    _recordTokenForensics(prompt);

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
      'stream': true,

      // TOKEN BUDGET
      'max_completion_tokens': maxTokens ?? 12000,
    };

    final payloadJson = jsonEncode(payload);
    PipelineDebugStore.lastRawProviderPayload = payloadJson;
    PipelineDebugStore.lastTimestamp = DateTime.now().toIso8601String();

    final content = await _streamGroqContent(
      payload: payload,
      requestedCases: _requestedObjectCount(prompt),
    ).timeout(const Duration(seconds: 90));
    if (content.trim().isEmpty) {
      throw Exception('Empty Groq response');
    }

    return _sanitize(content);
  }

  Future<String> _streamGroqContent({
    required Map<String, dynamic> payload,
    required int? requestedCases,
  }) async {
    final client = http.Client();
    final rawStream = StringBuffer();
    final content = StringBuffer();
    final recovery = StreamingJsonRecovery();

    try {
      final request = http.Request('POST', Uri.parse(_endpoint))
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(payload);

      final response = await client.send(request);
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        PipelineDebugStore.lastRawResponse = body;
        throw Exception('Groq error ${response.statusCode}: $body');
      }

      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        rawStream.writeln(line);
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;

        final data = trimmed.substring(5).trim();
        if (data.isEmpty || data == '[DONE]') continue;

        try {
          final decoded = jsonDecode(data);
          final delta =
              decoded['choices']?[0]?['delta']?['content']?.toString() ?? '';
          if (delta.isEmpty) continue;
          content.write(delta);
          recovery.addChunk(delta);
        } catch (_) {
          continue;
        }

        if (requestedCases != null && recovery.objectCount >= requestedCases) {
          break;
        }
      }

      final rawText = content.toString();
      PipelineDebugStore.lastRawResponse = rawText.isNotEmpty
          ? rawText
          : rawStream.toString();
      return _finalizeStreamRecovery(recovery, rawText);
    } finally {
      client.close();
    }
  }

  String _finalizeStreamRecovery(
    StreamingJsonRecovery recovery,
    String rawText,
  ) {
    final chunks = <String>[...recovery.drainObjects()];
    final pending = recovery.pendingChunk.trim();
    if (pending.isNotEmpty) chunks.add(pending);

    final recovered = recovery.recoverObjects(chunks);
    if (recovered.isNotEmpty) {
      PipelineDebugStore.partialRecoveryUsed = true;
      final recoveredText = jsonEncode(recovered);
      PipelineDebugStore.estimatedOutputTokens = _estimateTokens(recoveredText);
      return recoveredText;
    }

    PipelineDebugStore.estimatedOutputTokens = _estimateTokens(rawText);
    return rawText;
  }

  int? _requestedObjectCount(String prompt) {
    final match = RegExp(
      r'Return (?:exactly|up to)\s+(\d+)\s+(?:JSON objects|ordered JSON cases)',
      caseSensitive: false,
    ).firstMatch(prompt);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  void _recordTokenForensics(String prompt) {
    PipelineDebugStore.estimatedInputTokens =
        _estimateTokens(SystemPrompt.systemInstruction) +
        _estimateTokens(prompt);
    PipelineDebugStore.estimatedSavedTokens = 0;
  }

  int _estimateTokens(String value) {
    if (value.trim().isEmpty) return 0;
    return (value.length / 4).ceil();
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
