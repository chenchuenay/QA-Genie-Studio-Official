import 'package:qa_genie/core/validators/structural_case_validator.dart';
import 'dart:convert';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/enums/test_case_origin.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';

class ResponseParser {
  static List<TestCaseModel> parseArray(String cleaned) {
    PipelineDebugStore.resetParserSalvageCounters();
    final normalized = cleaned.trim();
    if (normalized.isEmpty) throw Exception('AI response is empty');
    if (normalized.length < 20) throw Exception('AI response too short');

    // Phase 6: Truncation detection
    final looksTruncated =
        normalized.startsWith('[') && !normalized.endsWith(']');
    PipelineDebugStore.truncatedResponseDetected = looksTruncated;

    final repaired = _normalizeJsArtifacts(normalized);
    final decodedFull = _attemptFullStructuralDecode(repaired);
    final testCases = <TestCaseModel>[];

    if (decodedFull != null) {
      final maps = <Map<String, dynamic>>[];
      _flattenDecoded(decodedFull, maps, countStructuralSkips: true);
      testCases.addAll(maps.map((m) {
          final tc = TestCaseModel.fromJson(m);
          tc.forensicOrigin = TestCaseOrigin.ai;
          return tc;
      }));
      PipelineDebugStore.partialRecoveryUsed = false;
    } else {
      PipelineDebugStore.partialRecoveryUsed = true;
      testCases.addAll(salvageObjects(repaired));
      if (testCases.isEmpty) {
        testCases.addAll(_salvageMaps(repaired));
        if (testCases.isEmpty) throw Exception('No valid JSON objects found');
      }
    }
    PipelineDebugStore.recoveredObjectCount = testCases.length;
    if (testCases.length > 200) throw Exception('AI response too large');
    return testCases;
  }

  static List<TestCaseModel> salvageObjects(String raw) {
    final testCases = <TestCaseModel>[];
    final chunks = _extractJsonObjects(raw);

    for (final chunk in chunks) {
      try {
        final repaired = _repairObject(chunk);
        final parsed = jsonDecode(repaired);
        
        if (parsed is! Map<String, dynamic>) {
          PipelineDebugStore.rejectedObjectCount++;
          PipelineDebugStore.rejectedObjects.add({
            'object': parsed,
            'reason': 'Parsed object is not a Map/JSON object',
          });
          continue;
        }

        if (!StructuralCaseValidator.isValid(parsed)) {
          PipelineDebugStore.invalidCasesDropped++;
          PipelineDebugStore.rejectedObjects.add({
            'object': parsed,
            'reason': 'StructuralCaseValidator.isValid failed',
          });
          continue;
        }

        if (repaired != chunk) {
          PipelineDebugStore.repairedObjects.add({
            'before': chunk,
            'after': repaired,
            'operation': 'bracket_repair_and_trailing_commas',
          });
        }

        final tc = TestCaseModel.fromJson(parsed);
        tc.forensicOrigin = TestCaseOrigin.ai;
        if (repaired != chunk) {
          tc.repairOperations.add('bracket_repair_and_trailing_commas');
        }
        
        testCases.add(tc);
      } catch (e) {
        PipelineDebugStore.rejectedObjectCount++;
        PipelineDebugStore.rejectedObjects.add({
          'raw_chunk': chunk,
          'reason': 'jsonDecode failed: ${e.toString()}',
        });
        continue;
      }
    }

    return testCases;
  }

  static List<TestCaseModel> salvagePartialObjects(String raw) {
    return salvageObjects(raw);
  }

  static List<String> _extractJsonObjects(String raw) {
    final results = <String>[];
    int depth = 0;
    bool insideString = false;
    bool escaping = false;
    final buffer = StringBuffer();

    for (int i = 0; i < raw.length; i++) {
      final c = raw[i];

      if (escaping) {
        if (depth > 0) buffer.write(c);
        escaping = false;
        continue;
      }

      if (c == '\\' && insideString) {
        if (depth > 0) buffer.write(c);
        escaping = true;
        continue;
      }

      if (c == '"') {
        if (depth > 0) buffer.write(c);
        insideString = !insideString;
        continue;
      }

      if (!insideString) {
        if (c == '{') {
          if (depth == 0) buffer.clear();
          depth++;
          buffer.write(c);
          continue;
        }

        if (c == '}') {
          if (depth > 0) {
            depth--;
            buffer.write(c);
            if (depth == 0) {
              results.add(buffer.toString());
              buffer.clear();
            }
          }
          continue;
        }
      }

      if (depth > 0) buffer.write(c);
    }

    if (buffer.isNotEmpty) {
      results.add(buffer.toString());
    }

    return results;
  }

  static String _repairObject(String raw) {
    var fixed = raw.trim();
    if (fixed.isEmpty) return fixed;

    fixed = fixed.replaceAll(RegExp(r',\s*}'), '}');
    fixed = fixed.replaceAll(RegExp(r',\s*]'), ']');

    final stack = <String>[];
    bool insideString = false;
    bool escaping = false;

    for (int i = 0; i < fixed.length; i++) {
      final c = fixed[i];

      if (escaping) {
        escaping = false;
        continue;
      }

      if (c == '\\' && insideString) {
        escaping = true;
        continue;
      }

      if (c == '"') {
        insideString = !insideString;
        continue;
      }

      if (insideString) continue;

      if (c == '{' || c == '[') {
        stack.add(c);
        continue;
      }

      if (c == '}' || c == ']') {
        if (stack.isEmpty) continue;
        final expectedOpener = c == '}' ? '{' : '[';
        if (stack.last == expectedOpener) {
          stack.removeLast();
        }
      }
    }

    for (final opener in stack.reversed) {
      fixed += opener == '{' ? '}' : ']';
    }

    fixed = fixed.replaceAll(RegExp(r',\s*}'), '}');
    fixed = fixed.replaceAll(RegExp(r',\s*]'), ']');

    return fixed;
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
      if (decoded != null) return _unwrapKnownLists(decoded);
    }
    return null;
  }

  static List<String> _deriveSoftenedArrays(String raw) {
    final softened = <String>{};
    final env = _firstBalancedEnvelope(raw);
    if (env == null || env.length < 2 || !env.startsWith('['))
      return softened.toList();
    final parts = _splitTopLevelSeparated(
      env.substring(1, env.length - 1),
      ',',
    );
    if (parts.isEmpty) return softened.toList();
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

  static dynamic _unwrapKnownLists(dynamic decoded) {
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      for (final key in ['cases', 'testCases', 'tests', 'items', 'data']) {
        final v = map[key];
        if (v is List) return v;
        if (v is Map) return [Map<String, dynamic>.from(v)];
      }
    }
    return decoded;
  }

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
        if (map != null) sink.add(map);
      }
      return;
    }
    final mapOnly = node is Map
        ? _safeMap(node, bumpRejections: countStructuralSkips)
        : null;
    if (mapOnly != null) sink.add(mapOnly);
    if (countStructuralSkips && node is! Map && node is! List)
      PipelineDebugStore.rejectedObjectCount++;
  }

  static Map<String, dynamic>? _safeMap(
    dynamic raw, {
    bool bumpRejections = true,
  }) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      try {
        return Map<String, dynamic>.from(raw);
      } catch (_) {
        if (bumpRejections) PipelineDebugStore.rejectedObjectCount++;
        return null;
      }
    }
    if (bumpRejections) PipelineDebugStore.rejectedObjectCount++;
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

  static List<String> _splitArrayIntoObjects(String arrayStr) {
    final results = <String>[];
    if (!arrayStr.startsWith('[') || !arrayStr.endsWith(']')) return results;
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
      if (inString) continue;
      if (ch == '{') {
        if (braceDepth == 0) start = i;
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
          if (obj.isNotEmpty) results.add(obj);
          start = -1;
        }
      }
    }
    return results;
  }

  static List<TestCaseModel> _salvageMaps(String repaired) {
    final results = <TestCaseModel>[];
    
    void tryIngestString(String snippet) {
      final trimmed = snippet.trim();
      if (trimmed.isEmpty) return;
      final decoded = _decodeLoose(trimmed);
      if (decoded == null) {
        PipelineDebugStore.rejectedObjectCount++;
        return;
      }
      
      final extracted = <Map<String, dynamic>>[];
      _flattenDecoded(decoded, extracted, countStructuralSkips: true);
      
      for (final map in extracted) {
        if (StructuralCaseValidator.isValid(map)) {
          final tc = TestCaseModel.fromJson(map);
          tc.forensicOrigin = TestCaseOrigin.ai;
          results.add(tc);
        } else {
          PipelineDebugStore.invalidCasesDropped++;
        }
      }
    }

    final envelope = _firstBalancedEnvelope(repaired);
    if (envelope != null && envelope.trim().startsWith('[')) {
      final objects = _splitArrayIntoObjects(envelope);
      for (final objStr in objects) tryIngestString(objStr);
    } else {
      final targets = <String>{repaired};
      if (envelope != null) targets.add(envelope.trim());
      for (final chunk in targets) {
        tryIngestString(chunk);
        for (final braceObject in _collectBalancedBraceObjects(chunk))
          tryIngestString(braceObject);
      }
    }
    return results;
  }

  static String _normalizeJsArtifacts(String normalized) {
    var repaired = normalized;
    repaired = repaired.replaceAllMapped(
      RegExp(r'"((?:[^"\\\\]|\\\\.)*)"\s*\.repeat\(\s*(\d+)\s*\)'),
      (m) {
        final text = jsonDecode('"${m.group(1)}"') as String;
        final count = (int.tryParse(m.group(2)!) ?? 1).clamp(1, 1024);
        return jsonEncode(List.filled(count, text).join());
      },
    );
    repaired = repaired.replaceAllMapped(
      RegExp(
        r'"([^"\\\\]*)"\.replace\("([^"\\\\]*)",\s*"([^"\\\\]*)"\)\s*\+\s*"([^"\\\\]*)"',
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
        RegExp(r'"([^"\\\\]*)"\s*\+\s*"([^"\\\\]*)"'),
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
    if (anchor == null) return null;
    final closing = _closingDelimiterIndex(input, anchor);
    if (closing == null) return null;
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
      if (!inString && (ch == '{' || ch == '[')) return i;
    }
    return null;
  }

  static int? _closingDelimiterIndex(String source, int startIndex) {
    if (startIndex >= source.length) return null;
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
      if (!inString) depth += weights[ch] ?? 0;
      if (!inString && depth == 0) return i;
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
        if (ch == '{' || ch == '[')
          depth++;
        else if (ch == '}' || ch == ']')
          if (depth > 0) depth--;
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
        final title = (map['title'] ?? '').toString().trim();
        if (title.length < 5) {
          PipelineDebugStore.malformedObjectsSkipped++;
          PipelineDebugStore.rejectedObjects.add({
            'object': map,
            'reason': 'Title too short (< 5 chars)',
          });
          continue;
        }
        final normalizedTitle = title
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
            .trim();
        if (seenTitles.contains(normalizedTitle)) {
          PipelineDebugStore.rejectedObjects.add({
            'object': map,
            'reason': 'Duplicate title detected',
          });
          continue;
        }
        final tc = TestCaseModel.fromJson(map);
        tc.forensicOrigin = TestCaseOrigin.ai;
        if (tc.preconditions.isEmpty)
          tc.preconditions = ['Application is installed and accessible'];
        if (tc.expectedResult.trim().isEmpty)
          tc.expectedResult = 'Application processes the workflow successfully';
        if (!TestCaseModel.isValid(tc)) {
          PipelineDebugStore.malformedObjectsSkipped++;
          PipelineDebugStore.rejectedObjects.add({
            'object': map,
            'reason': 'TestCaseModel.isValid failed (field length or content rules)',
          });
          continue;
        }
        seenTitles.add(normalizedTitle);
        parsedCases.add(tc);
      } catch (_) {
        PipelineDebugStore.malformedObjectsSkipped++;
      }
    }
    if (parsedCases.isEmpty)
      throw Exception('All parsed testcases were invalid');
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
      if (_seen.add(key)) records.add(Map<String, dynamic>.from(map));
    }
  }
}
