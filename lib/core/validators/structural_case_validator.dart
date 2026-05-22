class StructuralCaseValidator {
  static bool isValid(Map<String, dynamic> obj) {
    final required = [
      'title',
      'priority',
      'type',
      'preconditions',
      'steps',
      'expectedResult',
    ];
    for (final field in required) {
      if (!obj.containsKey(field)) {
        return false;
      }
    }
    if (obj['steps'] is! List) {
      return false;
    }
    final steps = obj['steps'] as List;
    if (steps.length < 2 || steps.length > 5) {
      return false;
    }
    for (final step in steps) {
      if (step is! Map<String, dynamic>) {
        return false;
      }
      if ((step['action'] ?? '').toString().length < 12) {
        return false;
      }
      if ((step['expected'] ?? '').toString().length < 20) {
        return false;
      }
    }
    return true;
  }
}
