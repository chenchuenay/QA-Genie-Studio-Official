import 'test_case.dart';
// lib/domain/entities/test_suite.dart


class TestSuite {
  final String id;

  /// Visible suite name
  final String name;

  /// Main module grouping
  final String module;

  /// Feature under testing
  final String feature;

  /// CORE / PRO
  final String generationMode;

  /// User custom instructions
  final String? constraints;

  /// Pipeline forensic id
  final String traceId;

  /// Immutable finalized test cases
  final List<TestCase> testCases;

  /// Epoch milliseconds
  final int createdAt;

  /// Cached count for performance
  final int totalCases;

  const TestSuite({
    required this.id,
    required this.name,
    required this.module,
    required this.feature,
    required this.generationMode,
    required this.traceId,
    required this.testCases,
    required this.createdAt,
    required this.totalCases,
    this.constraints,
  });

  bool get isEmpty => testCases.isEmpty;

  bool get isPro {
    return generationMode.toLowerCase() == 'pro';
  }

  bool get hasConstraints {
    return constraints != null && constraints!.trim().isNotEmpty;
  }
}
