import 'dart:convert';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';

class ResponseParser {
  /// Salvage-first ingestion: salvage executes only after full-structure decode fails,
  /// so recoverable payloads are preserved without additional provider calls.
  static List<TestCaseModel> parseArray(String cleaned) {
    PipelineDebugStore.resetParserSalvageCounters();

    final normalized = cleaned.trim();

    if (normalized.isEmpty) {
      throw Exception('AI response is empty');
    }

    if (normalized.length < 20) {
      throw Exception('AI response too short');
    }

    final repaired = _normalizeJsArtifacts(normalized);

    final decodedFull = _attemptFullStructuralDecode(repaired);

    final maps = <Map<String, dynamic>>[];

    if (decodedFull != null) {
      _flattenDecoded(decodedFull, maps, countStructuralSkips: true);
      PipelineDebugStore.partialRecoveryUsed = false;
    } else {
      PipelineDebugStore.partialRecoveryUsed = true;
      maps.addAll(_salvageMaps(repaired));
      if (maps.isEmpty) {
        throw Exception('No valid JSON objects found');
      }
    }

    PipelineDebugStore.recoveredObjectCount = maps.length;

    if (maps.length > 200) {
      throw Exception('AI response too large');
    }

    return _buildModels(maps);
  }

  static dynamic _attemptFullStructuralDecode(String source) {
    final candidates = <String>{source, _sanitizeMalformedDelimiters(source)};

    final envelope = _firstBalancedEnvelope(source);
    if (envelope != null) {
      candidates.add(envelope);
      candidates.add(_sanitizeMalformedDelimiters(envelope));
    }

    candidates.addAll(_deriveSoftenedArrays(source));

    for (final candidate in candidates) {
      final decoded = _decodeLoose(candidate);
      if (decoded != null) {
        return _unwrapKnownLists(decoded);
      }
    }
    return null;
  }

  static List<String> _deriveSoftenedArrays(String raw) {
    final softened = <String>{};
    final env = _firstBalancedEnvelope(raw);
    if (env == null || env.length < 2 || !env.startsWith('[')) {
      return softened.toList();
    }

    final parts = _splitTopLevelSeparated(
      env.substring(1, env.length - 1),
      ',',
    );
    if (parts.isEmpty) {
      return softened.toList();
    }

    for (var i = parts.length; i >= 1; i--) {
      final candidate = '[' + parts.take(i).join(',') + ']';
      final repaired = _sanitizeMalformedDelimiters(candidate);
      if (_decodeLoose(repaired) != null) {
        softened.add(repaired);
        break;
      }
    }

    return softened.toList();
  }

  /// Unwraps known provider envelopes such as `{ "cases": [...] }`.
  static dynamic _unwrapKnownLists(dynamic decoded) {
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      for (final key in ['cases', 'testCases', 'tests', 'items', 'data']) {
        final v = map[key];
        if (v is List) {
          return v;
        }
        if (v is Map) {
          return [Map<String, dynamic>.from(v)];
        }
      }
    }
    return decoded;
  }

  /// Flattens lists / maps produced by salvage or canonical decode paths.
  static void _flattenDecoded(
    dynamic decoded,
    List<Map<String, dynamic>> sink, {
    required bool countStructuralSkips,
  }) {
    var node = _unwrapKnownLists(decoded);

    if (node is List) {
      for (final raw in node) {
        final map = _safeMap(
          raw,
          bumpRejections:
              countStructuralSkips &&
              raw is! Map &&
              raw is! Map<String, dynamic>,
        );
        if (map != null) {
          sink.add(map);
        }
      }
      return;
    }

    final mapOnly = node is Map
        ? _safeMap(node, bumpRejections: countStructuralSkips)
        : null;
    if (mapOnly != null) {
      sink.add(mapOnly);
      return;
    }

    if (countStructuralSkips) {
      PipelineDebugStore.rejectedObjectCount++;
    }
  }

  static Map<String, dynamic>? _safeMap(
    dynamic raw, {
    bool bumpRejections = true,
  }) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      try {
        return Map<String, dynamic>.from(raw);
      } catch (_) {
        if (bumpRejections) PipelineDebugStore.rejectedObjectCount++;
        return null;
      }
    }
    if (bumpRejections) {
      PipelineDebugStore.rejectedObjectCount++;
    }
    return null;
  }

  static dynamic _decodeLoose(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }

  /// Splits an array string into individual object strings, handling nested braces.
  static List<String> _splitArrayIntoObjects(String arrayStr) {
    final results = <String>[];

    if (!arrayStr.startsWith('[') || !arrayStr.endsWith(']')) {
      return results;
    }

    final inner = arrayStr.substring(1, arrayStr.length - 1);

    bool inString = false;
    bool escape = false;

    int braceDepth = 0;
    int start = -1;

    for (int i = 0; i < inner.length; i++) {
      final ch = inner[i];

      if (escape) {
        escape = false;
        continue;
      }

      if (ch == '\\' && inString) {
        escape = true;
        continue;
      }

      if (ch == '"') {
        inString = !inString;
        continue;
      }

      if (inString) {
        continue;
      }

      if (ch == '{') {
        if (braceDepth == 0) {
          start = i;
        }
        braceDepth++;
      } else if (ch == '}') {
        braceDepth--;

        if (braceDepth < 0) {
          braceDepth = 0;
          start = -1;
          continue;
        }

        if (braceDepth == 0 && start != -1) {
          final obj = inner.substring(start, i + 1).trim();

          if (obj.isNotEmpty) {
            results.add(obj);
          }

          start = -1;
        }
      }
    }

    return results;
  }

  /// Stage 2 salvage: chunked decode + greedy brace slicing over the envelope + prose.
  static List<Map<String, dynamic>> _salvageMaps(String repaired) {
    final collector = _UniqueMapAccumulator();

    void tryIngestString(String snippet) {
      final trimmed = snippet.trim();
      if (trimmed.isEmpty) {
        return;
      }
      final decoded = _decodeLoose(trimmed);
      if (decoded == null) {
        PipelineDebugStore.rejectedObjectCount++;
        return;
      }

      final extracted = <Map<String, dynamic>>[];
      _flattenDecoded(decoded, extracted, countStructuralSkips: true);
      collector.addMany(extracted);
    }

    // First, try to extract the outermost array and split it into individual objects
    final envelope = _firstBalancedEnvelope(repaired);
    if (envelope != null && envelope.trim().startsWith('[')) {
      final objects = _splitArrayIntoObjects(envelope);
      for (final objStr in objects) {
        tryIngestString(objStr);
      }
    } else {
      // Fall back to the original method
      final targets = <String>{repaired};
      if (envelope != null) targets.add(envelope.trim());
      for (final chunk in targets) {
        tryIngestString(chunk);
        for (final braceObject in _collectBalancedBraceObjects(chunk)) {
          tryIngestString(braceObject);
        }
      }
    }

    return collector.records;
  }

  static String _normalizeJsArtifacts(String normalized) {
    var repaired = normalized;

    repaired = repaired.replaceAllMapped(
      RegExp(r'"((?:[^"\\]|\\.)*)"\s*\.repeat\(\s*(\d+)\s*\)'),
      (m) {
        final text = jsonDecode('"${m.group(1)}"') as String;
        final count = (int.tryParse(m.group(2)!) ?? 1).clamp(1, 1024);
        return jsonEncode(List.filled(count, text).join());
      },
    );
    repaired = repaired.replaceAllMapped(
      RegExp(
        r'"([^"\\]*)"\.replace\("([^"\\]*)",\s*"([^"\\]*)"\)\s*\+\s*"([^"\\]*)"',
      ),
      (m) {
        final text = m.group(1)!;
        final from = m.group(2)!;
        final to = m.group(3)!;
        final suffix = m.group(4)!;
        return jsonEncode(text.replaceAll(from, to) + suffix);
      },
    );

    var previous = '';
    while (previous != repaired) {
      previous = repaired;
      repaired = repaired.replaceAllMapped(
        RegExp(r'"([^"\\]*)"\s*\+\s*"([^"\\]*)"'),
        (m) => jsonEncode(m.group(1)! + m.group(2)!),
      );
    }
    return repaired;
  }

  static String _sanitizeMalformedDelimiters(String text) {
    var cleaned = text
        .replaceAll(RegExp(r',(\s*[\]}])'), r'$1')
        .replaceAll(RegExp(r',\s*$'), '')
        .replaceAll(RegExp(r',\s*\]'), ']')
        .replaceAll(RegExp(r',\s*\}'), '}');

    var previous = '';
    while (previous != cleaned) {
      previous = cleaned;
      cleaned = cleaned
          .replaceAll(RegExp(r',\s*$'), '')
          .replaceAll(RegExp(r'\[\s*,'), '[')
          .replaceAll(RegExp(r'{\s*,'), '{')
          .trim();
    }

    return cleaned;
  }

  static String? _firstBalancedEnvelope(String input) {
    final anchor = _firstStructuralOpenIndex(input);

    if (anchor == null) {
      return null;
    }

    final closing = _closingDelimiterIndex(input, anchor);

    if (closing == null) {
      return null;
    }

    return input.substring(anchor, closing + 1).trim();
  }

  static int? _firstStructuralOpenIndex(String raw) {
    bool inString = false;
    bool escape = false;

    for (int i = 0; i < raw.length; i++) {
      final ch = raw[i];

      if (escape) {
        escape = false;
        continue;
      }

      if (ch == '\\' && inString) {
        escape = true;
        continue;
      }

      if (ch == '"') {
        inString = !inString;
        continue;
      }

      if (!inString && (ch == '{' || ch == '[')) {
        return i;
      }
    }

    return null;
  }

  static int? _closingDelimiterIndex(String source, int startIndex) {
    if (startIndex >= source.length) {
      return null;
    }

    final opener = source[startIndex];

    late final Map<String, int> weights;

    switch (opener) {
      case '[':
        weights = {'[': 1, ']': -1};
        break;

      case '{':
        weights = {'{': 1, '}': -1};
        break;

      default:
        return null;
    }

    int depth = 0;
    bool inString = false;
    bool escape = false;

    for (int i = startIndex; i < source.length; i++) {
      final ch = source[i];

      if (escape) {
        escape = false;
        continue;
      }

      if (ch == '\\' && inString) {
        escape = true;
        continue;
      }

      if (ch == '"') {
        inString = !inString;
        continue;
      }

      if (!inString) {
        depth += weights[ch] ?? 0;
      }

      if (!inString && depth == 0) {
        return i;
      }
    }

    return null;
  }

  static List<String> _splitTopLevelSeparated(String fragment, String token) {
    final pieces = <String>[];
    final buf = StringBuffer();

    bool inString = false;
    bool escape = false;
    int depth = 0;

    for (int i = 0; i < fragment.length; i++) {
      final ch = fragment[i];

      if (escape) {
        escape = false;
        buf.write(ch);
        continue;
      }

      if (ch == '\\' && inString) {
        escape = true;
        buf.write(ch);
        continue;
      }

      if (ch == '"') {
        inString = !inString;
        buf.write(ch);
        continue;
      }

      if (!inString) {
        if (ch == '{' || ch == '[') {
          depth++;
        } else if (ch == '}' || ch == ']') {
          if (depth > 0) depth--;
        }

        if (ch == token && depth == 0) {
          pieces.add(buf.toString());
          buf.clear();
          continue;
        }
      }

      buf.write(ch);
    }

    pieces.add(buf.toString());

    return pieces.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static List<String> _collectBalancedBraceObjects(String haystack) {
    final results = <String>[];

    int cursor = 0;
    bool inString = false;
    bool escape = false;

    while (cursor < haystack.length) {
      final char = haystack[cursor];

      if (escape) {
        escape = false;
        cursor++;
        continue;
      }

      if (char == '\\' && inString) {
        escape = true;
        cursor++;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        cursor++;
        continue;
      }

      if (!inString && char == '{') {
        final close = _closingDelimiterIndex(haystack, cursor);

        if (close != null) {
          results.add(haystack.substring(cursor, close + 1));

          cursor = close + 1;
          continue;
        }
      }

      cursor++;
    }

    return results;
  }

  static List<TestCaseModel> _buildModels(
    List<Map<String, dynamic>> decodedList,
  ) {
    final parsedCases = <TestCaseModel>[];

    final seenTitles = <String>{};

    for (final item in decodedList) {
      try {
        final map = Map<String, dynamic>.from(item);

        map['source'] = CaseSource.ai.name;

        map['steps'] ??= [];
        map['preconditions'] ??= [];

        map['id'] ??= '';
        map['module'] ??= '';
        map['feature'] ??= '';
        map['platform'] ??= '';
        map['priority'] ??= 'Medium';
        map['type'] ??= 'Functional';
        map['expectedResult'] ??= '';
        map['actualResult'] ??= '';
        map['status'] ??= 'Not Executed';

        final title = (map['title'] ?? '').toString().trim();

        if (title.length < 5) {
          PipelineDebugStore.malformedObjectsSkipped++;
          continue;
        }

        final normalizedTitle = title
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
            .trim();

        if (seenTitles.contains(normalizedTitle)) {
          continue;
        }

        final tc = TestCaseModel.fromJson(map);

        while (tc.steps.length < 3) {
          tc.steps.add(
            TestStep(
              action: 'Validate application behavior',
              data: '',
              expected: 'Application behaves correctly and remains stable',
            ),
          );
        }

        if (tc.preconditions.isEmpty) {
          tc.preconditions = ['Application is installed and accessible'];
        }

        if (tc.expectedResult.trim().isEmpty) {
          tc.expectedResult = 'Application processes the workflow successfully';
        }

        if (!TestCaseModel.isValid(tc)) {
          PipelineDebugStore.malformedObjectsSkipped++;

          print('❌ VALIDATION FAILED');
          print('TITLE: ${tc.title}');
          print('MODULE: ${tc.module}');
          print('FEATURE: ${tc.feature}');
          print('TYPE: ${tc.type}');
          print('PRIORITY: ${tc.priority}');
          print('PRECONDITIONS: ${tc.preconditions.length}');
          print('STEPS: ${tc.steps.length}');
          print('EXPECTED RESULT: ${tc.expectedResult}');
          print('RAW MAP: $map');

          continue;
        }

        seenTitles.add(normalizedTitle);

        parsedCases.add(tc);
      } catch (e, st) {
        PipelineDebugStore.malformedObjectsSkipped++;

        print('❌ TC PARSE FAILURE');
        print('ERROR: $e');
        print('STACK: $st');
        print('RAW MAP: $item');
      }
    }

    if (parsedCases.isEmpty) {
      throw Exception('All parsed testcases were invalid');
    }

    return parsedCases;
  }
}

class _UniqueMapAccumulator {
  final _seen = <String>{};

  final records = <Map<String, dynamic>>[];

  static String _fingerprint(Map<String, dynamic> map) {
    try {
      return const JsonEncoder()
          .convert(map)
          .replaceAll(RegExp(r'\s+'), '')
          .toLowerCase();
    } catch (_) {
      return map.toString().toLowerCase();
    }
  }

  void addMany(List<Map<String, dynamic>> blobs) {
    for (final map in blobs) {
      final key = _fingerprint(map);

      if (_seen.add(key)) {
        records.add(Map<String, dynamic>.from(map));
      }
    }
  }
}
