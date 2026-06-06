class PartialCaseExtractor {
  const PartialCaseExtractor();

  List<Map<String, dynamic>> extractValidCases(
    List<dynamic> rawCases, [
    List<String>? errors,
  ]) {
    final valid = <Map<String, dynamic>>[];

    for (int i = 0; i < rawCases.length; i++) {
      final raw = rawCases[i];
      if (raw is! Map<String, dynamic>) {
        errors?.add('Case #$i: not a map, type=${raw.runtimeType}');
        continue;
      }

      if (_isValid(raw, errors, i)) {
        valid.add(raw);
      }
    }

    return valid;
  }

  bool _isValid(Map<String, dynamic> raw, List<String>? errors, int index) {
    final title = raw['title']?.toString() ?? '';
    final steps = raw['steps'];

    if (title.trim().isEmpty) {
      errors?.add('Case #$index: title is empty or missing');
      return false;
    }

    if (steps is! List || steps.isEmpty) {
      errors?.add('Case #$index: steps is not a non‑empty list');
      return false;
    }

    return true;
  }
}
