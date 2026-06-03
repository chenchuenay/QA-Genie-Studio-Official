// lib/engine/parsers/schema_normalizer.dart

class SchemaNormalizer {
  const SchemaNormalizer();

  Map<String, dynamic> normalizeCase(Map<String, dynamic> raw) {
    return {
      'id': _string(raw['id'] ?? raw['testCaseId'] ?? raw['test_case_id']),

      'title': _string(
        raw['title'] ??
            raw['test_case_title'] ??
            raw['testTitle'] ??
            raw['test_case_name'] ??
            raw['name'] ??
            raw['scenario'] ??
            raw['test_name'],
      ),

      'module': _string(raw['module'] ?? raw['moduleName']),

      'feature': _string(raw['feature'] ?? raw['featureName']),

      'platform': _string(raw['platform'] ?? raw['targetPlatform']),

      'priority': _normalizePriority(raw['priority']),

      'type': _normalizeType(
        raw['type'] ??
            raw['test_type'] ??
            raw['category'] ??
            raw['testCaseType'] ??
            raw['case_type'],
      ),

      'categoryLock': _normalizeCategory(
        raw['categoryLock'] ??
            raw['category'] ??
            raw['type'] ??
            raw['test_type'] ??
            raw['testCaseType'],
      ),

      'preconditions': _stringList(
        raw['preconditions'] ??
            raw['preConditions'] ??
            raw['prerequisites'] ??
            raw['conditions'],
      ),

      'testData': _string(
        raw['testData'] ?? raw['test_data'] ?? raw['data'] ?? raw['inputData'],
      ),

      'steps': _normalizeSteps(raw['steps']),

      'expectedResult': _string(
        raw['expectedResult'] ??
            raw['expected_result'] ??
            raw['expectedResults'] ??
            raw['expected_results'] ??
            raw['expected'],
      ),

      'actualResult': _string(
        raw['actualResult'] ?? raw['actual_result'] ?? '',
      ),

      'status': _string(raw['status'] ?? 'Not Executed'),

      'constraints': _string(raw['constraints']),

      'intent_id': _string(raw['intent_id'] ?? raw['intentId']),
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

  String _normalizeCategory(dynamic value) {
    final category = _string(value).toLowerCase();

    if (category.contains('positive')) return 'positive';

    if (category.contains('negative')) return 'negative';

    if (category.contains('boundary')) return 'boundary';

    if (category.contains('edge')) return 'edge';

    if (category.contains('security')) return 'security';

    if (category.contains('session')) return 'session';

    if (category.contains('validation')) return 'validation';

    if (category.contains('accessibility')) return 'accessibility';

    if (category.contains('performance')) return 'performance';

    return category.isEmpty ? 'positive' : category;
  }

  List<Map<String, dynamic>> _normalizeSteps(dynamic steps) {
    if (steps is! List) {
      return [];
    }

    return steps.map((step) {
      if (step is Map) {
        return {
          'action': _string(
            step['action'] ?? step['step'] ?? step['description'],
          ),
          'expected': _string(
            step['expected'] ??
                step['expectedResult'] ??
                step['expected_result'],
          ),
          'data': _string(
            step['data'] ?? step['testData'] ?? step['test_data'],
          ),
        };
      }

      return {'action': _string(step), 'expected': '', 'data': ''};
    }).toList();
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => _string(e)).where((e) => e.isNotEmpty).toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
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
