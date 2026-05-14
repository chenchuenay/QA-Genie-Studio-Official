import 'dart:convert';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/engine/pipeline/models/pipeline_models.dart';

class AIResponseNormalizer {
  static final RegExp _jsonBlockPattern = RegExp(r'```json\s*([\s\S]*?)\s*```');
  static final RegExp _commentPattern = RegExp(r'//.*?$', multiLine: true);

  List<WorkingCase> normalize(String rawResponse, String origin) {
    final sanitized = _sanitize(rawResponse);
    final dynamic decoded = _parseJson(sanitized);
    
    if (decoded is! List) {
      throw const FormatException('AI response did not produce a JSON array.');
    }

    return decoded.map((caseEntry) {
      if (caseEntry is! Map<String, dynamic>) {
        throw const FormatException('Each AI case must be a JSON object.');
      }
      return _toWorkingCase(caseEntry, origin);
    }).toList();
  }

  String _sanitize(String raw) {
    var text = raw;
    final match = _jsonBlockPattern.firstMatch(text);
    if (match != null) {
      text = match.group(1) ?? text;
    } else {
      text = text.replaceAll('```json', '').replaceAll('```', '');
    }
    text = text.replaceAll(_commentPattern, '');
    return text.trim();
  }

  dynamic _parseJson(String raw) {
    try {
      return jsonDecode(raw);
    } catch (e) {
      // Basic manual fix attempt
      var fixed = raw.replaceAll('“', '"').replaceAll('”', '"');
      if (!fixed.startsWith('[') && fixed.contains('{')) fixed = '[$fixed]';
      return jsonDecode(fixed);
    }
  }

  WorkingCase _toWorkingCase(Map<String, dynamic> item, String origin) {
    return WorkingCase(
      id: (item['id'] ?? 'TEMP-ID').toString(),
      title: (item['title'] ?? 'Missing Title').toString(),
      module: (item['module'] ?? '').toString(),
      feature: (item['feature'] ?? '').toString(),
      platform: (item['platform'] ?? '').toString(),
      priority: (item['priority'] ?? 'Medium').toString(),
      type: (item['type'] ?? 'FUNCTIONAL').toString(),
      preconditions: List<String>.from((item['preconditions'] as List?) ?? []),
      steps: (item['steps'] as List?)
          ?.map((s) => TestStep.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      expectedResult: (item['expectedResult'] ?? '').toString(),
      actualResult: (item['actualResult'] ?? '').toString(),
      status: (item['status'] ?? 'Draft').toString(),
      metadata: CaseMetadata(origin: origin),
    );
  }
}
