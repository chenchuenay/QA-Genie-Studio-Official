class ResponseCleaner {
  static String clean(String raw) {
    if (raw.trim().isEmpty) {
      return '';
    }

    var cleaned = raw.trim();

    cleaned = _removeMarkdown(cleaned);
    cleaned = _removeThinkTags(cleaned);
    cleaned = _removeXmlArtifacts(cleaned);
    cleaned = _removeControlChars(cleaned);
    cleaned = _normalizeQuotes(cleaned);
    cleaned = _extractJsonEnvelope(cleaned);

    return cleaned.trim();
  }

  static String _removeMarkdown(String input) {
    return input
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll(RegExp(r'```', caseSensitive: false), '');
  }

  static String _removeThinkTags(String input) {
    return input
        .replaceAll(
          RegExp(r'<think>[\s\S]*?<\/think>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<thinking>[\s\S]*?<\/thinking>', caseSensitive: false),
          '',
        );
  }

  static String _removeXmlArtifacts(String input) {
    return input
        .replaceAll(RegExp(r'<\/?response>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<\/?json>', caseSensitive: false), '');
  }

  static String _removeControlChars(String input) {
    return input.replaceAll(RegExp(r'[\u0000-\u001F]'), ' ');
  }

  static String _normalizeQuotes(String input) {
    return input
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");
  }

  static String _extractJsonEnvelope(String input) {
    final arrayStart = input.indexOf('[');
    final arrayEnd = input.lastIndexOf(']');

    if (arrayStart != -1 && arrayEnd != -1 && arrayEnd > arrayStart) {
      return input.substring(arrayStart, arrayEnd + 1);
    }

    final objStart = input.indexOf('{');
    final objEnd = input.lastIndexOf('}');

    if (objStart != -1 && objEnd != -1 && objEnd > objStart) {
      return input.substring(objStart, objEnd + 1);
    }

    return input;
  }
}
