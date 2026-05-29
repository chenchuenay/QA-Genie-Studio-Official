import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/execution_intent.dart';

class QaRealismEnforcer {
  const QaRealismEnforcer._();

  static String humanizeTitle(String title, String context) {
    final cleaned = _clean(title);
    if (cleaned.isEmpty) {
      return 'Validate ${_clean(context)} workflow behavior';
    }
    return cleaned
        .replaceFirst(RegExp(r'^\s*verify\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^\s*test\s+', caseSensitive: false), '')
        .trim();
  }

  static String humanizeExpectedResult(
    String expected, {
    required String context,
    required String platform,
    ExecutionIntent? intent,
  }) {
    final cleaned = _clean(expected);
    if (cleaned.isEmpty || _isGeneric(cleaned)) {
      final target = _clean(context);
      if (platform.toLowerCase() == 'api') {
        return 'The response reflects the expected $target outcome with a valid status and payload.';
      }
      return 'The $target workflow reaches the expected user-visible state.';
    }
    return cleaned;
  }

  static List<TestStep> humanizeSteps(List<TestStep> steps) {
    return steps.map((step) {
      return TestStep(
        action: _clean(step.action),
        data: _clean(step.data),
        expected: _clean(step.expected),
      );
    }).toList();
  }

  static bool _isGeneric(String value) {
    final lower = value.toLowerCase();
    return lower == 'operation successful' ||
        lower == 'system works correctly' ||
        lower == 'workflow completed successfully';
  }

  static String _clean(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
