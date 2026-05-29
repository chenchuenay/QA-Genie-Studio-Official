// lib/engine/parsers/malformed_json_salvager.dart

class MalformedJsonSalvager {
  const MalformedJsonSalvager();

  String salvage(String raw) {
    var cleaned = raw.trim();

    cleaned = _removeMarkdown(cleaned);
    cleaned = _normalizeQuotes(cleaned);
    cleaned = _removeTrailingCommas(cleaned);
    cleaned = _balanceJson(cleaned);

    return cleaned;
  }

  String _removeMarkdown(String input) {
    return input.replaceAll('```json', '').replaceAll('```', '').trim();
  }

  String _normalizeQuotes(String input) {
    return input
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll("‘", "'")
        .replaceAll("’", "'");
  }

  String _removeTrailingCommas(String input) {
    return input.replaceAll(RegExp(r',\s*([\]}])'), r'$1');
  }

  String _balanceJson(String input) {
    final openCurly = '{'.allMatches(input).length;
    final closeCurly = '}'.allMatches(input).length;

    final openSquare = '['.allMatches(input).length;
    final closeSquare = ']'.allMatches(input).length;

    final curlyDiff = openCurly - closeCurly;
    final squareDiff = openSquare - closeSquare;

    final buffer = StringBuffer(input);

    for (var i = 0; i < curlyDiff; i++) {
      buffer.write('}');
    }

    for (var i = 0; i < squareDiff; i++) {
      buffer.write(']');
    }

    return buffer.toString();
  }
}
