import 'dart:convert';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/core/network/response_parser.dart';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';
import 'package:qa_genie/core/network/providers/ai_provider.dart';

class ApiClient {
  final AiProvider _provider;

  ApiClient(this._provider);

  Future<List<TestCaseModel>> generate(String prompt) async {
    final apiStopwatch = Stopwatch()..start();

    final rawText = await _provider.generate(prompt);

    apiStopwatch.stop();

    PipelineDebugStore.lastRawResponse = rawText;
    PipelineDebugStore.lastApiDurationMs = apiStopwatch.elapsedMilliseconds;

    final cleaned = _cleanRawResponse(rawText);

    PipelineDebugStore.lastCleanedResponse = cleaned;

    final parsed = ResponseParser.parseArray(cleaned);

    PipelineDebugStore.lastParsedCount = parsed.length;

    return parsed;
  }

  String _cleanRawResponse(String value) {
    var cleaned = value.trim();

    cleaned = cleaned
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .replaceAll('<think>', '')
        .replaceAll('</think>', '');

    cleaned = cleaned.trim();

    final arrayStart = cleaned.indexOf('[');

    if (arrayStart > 0) {
      cleaned = cleaned.substring(arrayStart);
    }

    final arrayEnd = cleaned.lastIndexOf(']');

    if (arrayEnd != -1) {
      cleaned = cleaned.substring(0, arrayEnd + 1);
    }

    cleaned = cleaned.trim();

    try {
      jsonDecode(cleaned);
    } catch (_) {
      // parser salvage handles malformed JSON
    }

    return cleaned;
  }
}
