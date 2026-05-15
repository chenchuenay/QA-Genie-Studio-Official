class ResponseCleaner {
  static String clean(String raw, String provider) {
    // =====================================================
    // INITIAL NORMALIZATION
    // =====================================================

    String text = raw.trim();

    if (text.isEmpty) {
      throw Exception('AI response is empty');
    }

    // =====================================================
    // REMOVE UTF / INVISIBLE CHARACTERS
    // =====================================================

    text = text
        .replaceAll('\uFEFF', '')
        .replaceAll('\u200B', '')
        .replaceAll('\u200C', '')
        .replaceAll('\u200D', '');

    // =====================================================
    // REMOVE THINKING / REASONING BLOCKS
    // =====================================================

    text = text.replaceAll(
      RegExp(
        r'<think>[\s\S]*?<\/think>',
        multiLine: true,
        caseSensitive: false,
      ),
      '',
    );

    // =====================================================
    // REMOVE MARKDOWN FENCES
    // =====================================================

    text = text
        .replaceAll('```json', '')
        .replaceAll('```JSON', '')
        .replaceAll('```Json', '')
        .replaceAll('```', '');

    // =====================================================
    // REMOVE COMMON AI PREFIXES
    // =====================================================

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

    // =====================================================
    // EXTRACT JSON ARRAY START
    // =====================================================

    final startIndex = text.indexOf('[');

    if (startIndex == -1) {
      throw Exception('No JSON array start found');
    }

    text = text.substring(startIndex).trim();

    // =====================================================
    // EXTRACT JSON ARRAY END
    // =====================================================

    final endIndex = text.lastIndexOf(']');

    if (endIndex == -1) {
      throw Exception('No JSON array end found');
    }

    if (endIndex <= startIndex) {
      throw Exception('Invalid JSON boundaries');
    }

    text = text.substring(0, endIndex + 1).trim();

    // =====================================================
    // BASIC SHAPE VALIDATION
    // =====================================================

    if (!text.startsWith('[')) {
      throw Exception('Response does not start with JSON array');
    }

    if (!text.endsWith(']')) {
      throw Exception('Response does not end with JSON array');
    }

    // =====================================================
    // EMPTY / SHORT SAFETY
    // =====================================================

    if (text.isEmpty) {
      throw Exception('Extracted JSON is empty');
    }

    if (text.length < 20) {
      throw Exception('Extracted JSON too short');
    }

    // =====================================================
    // INVALID RESPONSE DETECTION
    // =====================================================

    final lower = text.toLowerCase();

    final blockedPatterns = [
      '.repeat(',
      '<html',
      '<body',
      '<script',
      '</html>',
      'console.log',
      'function(',
      'undefined',
      'nan',
      'traceback',
      'exception:',
      'stack trace',
      'syntaxerror',
      'referenceerror',
    ];

    for (final pattern in blockedPatterns) {
      if (lower.contains(pattern)) {
        throw Exception('Invalid AI response detected');
      }
    }

    // =====================================================
    // REMOVE TRAILING COMMAS
    // =====================================================

    text = text.replaceAll(RegExp(r',(\s*[\]}])'), r'$1');

    // =====================================================
    // FINAL NORMALIZATION
    // =====================================================

    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

    // =====================================================
    // FINAL SAFETY CHECK
    // =====================================================

    if (text == '[]') {
      throw Exception('AI returned empty array');
    }

    return text;
  }
}
