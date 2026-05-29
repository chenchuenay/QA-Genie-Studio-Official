import 'test_step.dart';
// lib/domain/entities/test_case.dart

class TestCase {
  final String id;

  /// Test case title
  final String title;

  /// Module grouping
  final String module;

  /// Feature under validation
  final String feature;

  /// Android / iOS / Web / API
  final String platform;

  /// High / Medium / Low
  final String priority;

  /// Positive / Negative / Security / Validation
  final String type;

  /// Immutable category protection
  final String categoryLock;

  /// Preconditions required before execution
  final List<String> preconditions;

  /// Execution steps
  final List<TestStep> steps;

  /// Final expected outcome
  final String expectedResult;

  /// Filled manually during execution
  final String actualResult;

  /// Not Executed / Passed / Failed / Blocked
  final String status;

  /// AI / Manual / Imported
  final String source;

  /// Used for forensic tracing
  final String traceId;

  /// Epoch milliseconds
  final int createdAt;

  const TestCase({
    required this.id,
    required this.title,
    required this.module,
    required this.feature,
    required this.platform,
    required this.priority,
    required this.type,
    required this.categoryLock,
    required this.preconditions,
    required this.steps,
    required this.expectedResult,
    required this.actualResult,
    required this.status,
    required this.source,
    required this.traceId,
    required this.createdAt,
  });

  bool get isExecutable {
    return steps.isNotEmpty && expectedResult.trim().isNotEmpty;
  }

  bool get isPositive {
    return type.toLowerCase() == 'positive';
  }

  bool get isNegative {
    return type.toLowerCase() == 'negative';
  }

  bool get isSecurity {
    return categoryLock.toLowerCase() == 'security';
  }

  int get totalSteps => steps.length;
}
