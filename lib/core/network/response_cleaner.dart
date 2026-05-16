import 'package:qa_genie/core/debug/pipeline_debug_store.dart';

class ResponseCleaner {
  static String clean(String raw, String provider) {
    PipelineDebugStore.cleanerRepairCount = 0;

    String text = raw.trim();
    if (text.isEmpty) {
      return text;
    }

    text = text
        .replaceAll('\uFEFF', '')
        .replaceAll('\u200B', '')
        .replaceAll('\u200C', '')
        .replaceAll('\u200D', '');

    final before = text;

    text = text.replaceAll(
      RegExp(
        r'<(?:redacted_)?thinking>[\s\S]*?<\/(?:redacted_)?thinking>',
        multiLine: true,
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'<think>[\s\S]*?<\/redacted_thinking>',
        multiLine: true,
        caseSensitive: false,
      ),
      '',
    );

    text = text
        .replaceAll('```json', '')
        .replaceAll('```JSON', '')
        .replaceAll('```Json', '')
        .replaceAll('```', '');

    final prefixes = [
      'Here is the JSON:',
      'Here\'s the JSON:',
      'Sure! Here is the JSON:',
      'Sure! Here\'s the JSON:',
      'Below is the JSON:',
      'Response:',
      'Output:',
      'JSON:',
    ];
    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
      }
    }

    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

    text = text.replaceAll(RegExp(r',(\s*[\]}])'), r'$1');

    final after = text;
    if (before != after) {
      PipelineDebugStore.cleanerRepairCount++;
    }

    if (text == '[]') {
      return text;
    }

    return text;
  }
}
