// lib/engine/parsers/partial_case_extractor.dart

class PartialCaseExtractor {
  const PartialCaseExtractor();

  List<Map<String, dynamic>> extractValidCases(List<dynamic> rawCases) {
    final valid = <Map<String, dynamic>>[];

    for (final raw in rawCases) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }

      if (_isValid(raw)) {
        valid.add(raw);
      }
    }

    return valid;
  }

  bool _isValid(Map<String, dynamic> raw) {
    final title = raw['title']?.toString() ?? '';
    final steps = raw['steps'];

    if (title.trim().isEmpty) {
      return false;
    }

    if (steps is! List || steps.isEmpty) {
      return false;
    }

    return true;
  }
}
