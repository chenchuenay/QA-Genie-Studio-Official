// lib/engine/parsers/schema_normalizer.dart

class SchemaNormalizer {
  const SchemaNormalizer();

  Map<String, dynamic> normalizeCase(Map<String, dynamic> raw) {
    return {
      'id': _string(raw['id']),
      'title': _string(raw['title']),
      'module': _string(raw['module']),
      'feature': _string(raw['feature']),
      'platform': _string(raw['platform']),
      'priority': _normalizePriority(raw['priority']),
      'type': _normalizeType(raw['type']),
      'preconditions': _stringList(raw['preconditions']),
      'steps': _normalizeSteps(raw['steps']),
      'expectedResult': _string(
        raw['expectedResult'] ?? raw['expected_result'],
      ),
      'actualResult': _string(raw['actualResult'] ?? ''),
      'status': _string(raw['status'] ?? 'Not Executed'),
      'constraints': _string(raw['constraints']),
      'categoryLock': _string(raw['categoryLock']),
    };
  }

  List<Map<String, dynamic>> normalizeCases(List<dynamic> rawCases) {
    return rawCases
        .whereType<Map>()
        .map((e) => normalizeCase(Map<String, dynamic>.from(e)))
        .toList();
  }

  String _normalizePriority(dynamic value) {
    final priority = _string(value).toLowerCase();

    switch (priority) {
      case 'critical':
        return 'Critical';

      case 'high':
        return 'High';

      case 'medium':
        return 'Medium';

      case 'low':
        return 'Low';

      default:
        return 'Medium';
    }
  }

  String _normalizeType(dynamic value) {
    final type = _string(value);

    if (type.isEmpty) {
      return 'Functional';
    }

    return type;
  }

  List<Map<String, dynamic>> _normalizeSteps(dynamic steps) {
    if (steps is! List) {
      return [];
    }

    return steps.map((step) {
      if (step is Map<String, dynamic>) {
        return {
          'action': _string(step['action']),
          'expected': _string(step['expected']),
          'data': _string(step['data']),
        };
      }

      return <String, dynamic>{'action': '', 'expected': '', 'data': ''};
    }).toList();
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => _string(e)).toList();
    }

    return [];
  }

  String _string(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }
}
