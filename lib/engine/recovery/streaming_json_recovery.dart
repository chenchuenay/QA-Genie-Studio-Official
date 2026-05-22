import 'dart:convert';

import 'package:qa_genie/core/debug/pipeline_debug_store.dart';

class StreamingJsonRecovery {
  final StringBuffer _buffer = StringBuffer();
  int _braceDepth = 0;
  bool _insideString = false;
  bool _escaping = false;
  bool _capturing = false;
  final List<String> _objects = [];

  int get objectCount => _objects.length;

  String get pendingChunk => _buffer.toString();

  void addChunk(String chunk) {
    for (var i = 0; i < chunk.length; i++) {
      final char = chunk[i];

      if (!_capturing) {
        if (char == '{') {
          _capturing = true;
          _braceDepth = 1;
          _insideString = false;
          _escaping = false;
          _buffer
            ..clear()
            ..write(char);
        }
        continue;
      }

      _buffer.write(char);

      if (_escaping) {
        _escaping = false;
        continue;
      }

      if (char == r'\' && _insideString) {
        _escaping = true;
        continue;
      }

      if (char == '"') {
        _insideString = !_insideString;
        continue;
      }

      if (_insideString) continue;

      if (char == '{') {
        _braceDepth++;
      } else if (char == '}') {
        _braceDepth--;
      }

      if (_braceDepth == 0 && _buffer.toString().trim().endsWith('}')) {
        _objects.add(_buffer.toString());
        _buffer.clear();
        _capturing = false;
      }
    }
  }

  List<String> drainObjects() {
    return List.from(_objects);
  }

  String normalizeChunk(String raw) {
    return raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .trim()
        .replaceAll(RegExp(r'^,+'), '')
        .replaceAll(RegExp(r',+$'), '')
        .trim();
  }

  Map<String, dynamic>? tryParseObject(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
    return null;
  }

  Map<String, dynamic>? partialRecover(String raw) {
    final titleMatch = RegExp(r'"title"\s*:\s*"([^"]+)"').firstMatch(raw);
    if (titleMatch == null) {
      return null;
    }
    return {
      'title': titleMatch.group(1),
      'steps': <Map<String, dynamic>>[],
      'expectedResult': '',
    };
  }

  List<Map<String, dynamic>> recoverObjects(List<String> chunks) {
    final recovered = <Map<String, dynamic>>[];

    for (final raw in chunks) {
      final cleaned = normalizeChunk(raw);
      if (cleaned.isEmpty) continue;

      final parsed = tryParseObject(cleaned);
      if (parsed != null) {
        recovered.add(parsed);
        PipelineDebugStore.recoveredObjects++;
        continue;
      }

      final partial = partialRecover(cleaned);
      if (partial != null) {
        recovered.add(partial);
        PipelineDebugStore.recoveredObjects++;
      } else {
        PipelineDebugStore.droppedObjects++;
      }
    }

    return recovered;
  }
}
