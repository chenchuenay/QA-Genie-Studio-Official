import 'package:qa_genie/domain/enums/case_source.dart';

class TestStep {
  String action;
  String data;
  String expected;

  TestStep({this.action = '', this.data = '', this.expected = ''});

  factory TestStep.fromJson(Map<String, dynamic> j) {
    return TestStep(
      action: (j['action'] ?? '')
          .toString()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),

      data: (j['data'] ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim(),

      expected: (j['expected'] ?? '')
          .toString()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'action': action, 'data': data, 'expected': expected};
  }
}

class TestCaseModel {
  final CaseSource source;
  final int? dbId;

  String id;

  String title;
  String module;
  String feature;
  String platform;
  String priority;
  String type;

  List<String> preconditions;
  List<TestStep> steps;

  String expectedResult;
  String actualResult;
  String status;

  TestCaseModel({
    this.source = CaseSource.ai,
    this.dbId,
    this.id = '',
    this.title = '',
    this.module = '',
    this.feature = '',
    this.platform = '',
    this.priority = 'Medium',
    this.type = 'Functional',
    this.preconditions = const [],
    this.steps = const [],
    this.expectedResult = '',
    this.actualResult = '',
    this.status = 'Not Executed',
  });

  static bool isValid(TestCaseModel tc) {
    // Title
    if (tc.title.trim().length < 5) {
      return false;
    }

    // Expected result
    if (tc.expectedResult.trim().isEmpty) {
      return false;
    }

    // Priority normalization safety
    if (!['High', 'Medium', 'Low'].contains(tc.priority)) {
      return false;
    }

    // Steps existence
    if (tc.steps.isEmpty) {
      return false;
    }

    const bannedDataPhrases = {
      'test data',
      'valid data',
      'invalid data',
      'dummy data',
      'sample data',
      'lorem ipsum',
    };

    for (final s in tc.steps) {
      // Action required
      if (s.action.trim().length < 3) {
        return false;
      }

      // Expected required
      if (s.expected.trim().isEmpty) {
        return false;
      }

      // Reject obvious garbage
      final lowerData = s.data.toLowerCase();

      if (bannedDataPhrases.any(lowerData.contains)) {
        return false;
      }
    }

    return true;
  }

  String get stepsDisplayString {
    return steps
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value.action}')
        .join('\n');
  }

  TestCaseModel copy() {
    return TestCaseModel(
      source: source,
      dbId: dbId,
      id: id,
      title: title,
      module: module,
      feature: feature,
      platform: platform,
      priority: priority,
      type: type,
      preconditions: List<String>.from(preconditions),

      steps: steps
          .map(
            (s) =>
                TestStep(action: s.action, data: s.data, expected: s.expected),
          )
          .toList(),

      expectedResult: expectedResult,
      actualResult: actualResult,
      status: status,
    );
  }

  factory TestCaseModel.fromJson(Map<String, dynamic> j) {
    try {
      // ===== SAFE STEPS =====

      List<TestStep> parsedSteps = [];

      final rawSteps = j['steps'];

      if (rawSteps is List) {
        parsedSteps = rawSteps.map((step) {
          try {
            if (step is Map<String, dynamic>) {
              return TestStep.fromJson(step);
            }

            if (step is Map) {
              return TestStep.fromJson(Map<String, dynamic>.from(step));
            }

            return TestStep(
              action: step.toString(),
              expected: 'System responds correctly',
            );
          } catch (_) {
            return TestStep(
              action: 'Execute step',
              expected: 'System responds correctly',
            );
          }
        }).toList();
      }

      // ===== SAFE PRECONDITIONS =====

      List<String> parsedPreconditions = [];

      final rawPreconditions = j['preconditions'];

      if (rawPreconditions is List) {
        parsedPreconditions = rawPreconditions
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      // Auto recover missing preconditions
      if (parsedPreconditions.isEmpty) {
        parsedPreconditions = ['Application is accessible and stable'];
      }

      // Auto recover missing steps
      if (parsedSteps.isEmpty) {
        parsedSteps = [
          TestStep(
            action: 'Open the target workflow',
            expected: 'Workflow loads successfully',
          ),
          TestStep(
            action: 'Perform the intended action',
            expected: 'System processes the request correctly',
          ),
          TestStep(
            action: 'Verify final application state',
            expected: 'Application state updates correctly',
          ),
        ];
      }

      // ===== PRIORITY NORMALIZATION =====

      final rawPriority = (j['priority'] ?? 'Medium')
          .toString()
          .trim()
          .toLowerCase();

      String normalizedPriority;

      switch (rawPriority) {
        case 'high':
        case 'critical':
          normalizedPriority = 'High';
          break;

        case 'low':
          normalizedPriority = 'Low';
          break;

        default:
          normalizedPriority = 'Medium';
      }

      // ===== SOURCE NORMALIZATION =====

      final sourceName = (j['source'] ?? 'ai').toString();

      final parsedSource = CaseSource.values.firstWhere(
        (e) => e.name == sourceName,
        orElse: () => CaseSource.ai,
      );

      // ===== EXPECTED RESULT RECOVERY =====

      String expectedResult = (j['expectedResult'] ?? '')
          .toString()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (expectedResult.isEmpty) {
        expectedResult =
            'System processes the workflow correctly and maintains stable application behavior';
      }

      return TestCaseModel(
        source: parsedSource,

        dbId: j['dbId'] is int ? j['dbId'] as int : null,

        id: (j['id'] ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim(),

        title: (j['title'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),

        module: (j['module'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),

        feature: (j['feature'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),

        platform: (j['platform'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),

        priority: normalizedPriority,

        type: (j['type'] ?? 'Functional')
            .toString()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),

        preconditions: parsedPreconditions,

        steps: parsedSteps,

        expectedResult: expectedResult,

        actualResult: (j['actualResult'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),

        status: (j['status'] ?? 'Not Executed')
            .toString()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),
      );
    } catch (e) {
      throw Exception('TestCaseModel.fromJson failed: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'module': module,
      'feature': feature,
      'platform': platform,
      'priority': priority,
      'type': type,
      'preconditions': preconditions,
      'steps': steps.map((s) => s.toJson()).toList(),
      'expectedResult': expectedResult,
      'actualResult': actualResult,
      'status': status,
      'source': source.name,
      'dbId': dbId,
    };
  }
}
