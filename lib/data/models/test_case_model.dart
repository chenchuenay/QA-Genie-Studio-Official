import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/enums/execution_intent.dart';
import 'package:qa_genie/domain/enums/test_case_origin.dart';
import 'package:qa_genie/domain/entities/test_step.dart'; // ✅ canonical

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
  List<TestStep> steps; // canonical TestStep

  String expectedResult;
  String actualResult;
  String status;
  ExecutionIntent? intent;
  TestCaseOrigin forensicOrigin = TestCaseOrigin.ai;
  List<String> repairOperations = [];
  List<String> realismOperations = [];
  bool visibleToMember = true;

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
    this.intent,
    this.forensicOrigin = TestCaseOrigin.ai,
  });

  static bool isValid(TestCaseModel tc) {
    if (tc.title.trim().length < 5) return false;
    if (tc.expectedResult.trim().isEmpty) return false;
    if (!['High', 'Medium', 'Low'].contains(tc.priority)) return false;
    if (tc.steps.isEmpty) return false;
    const bannedDataPhrases = {
      'test data',
      'valid data',
      'invalid data',
      'dummy data',
      'sample data',
      'lorem ipsum',
    };
    for (final s in tc.steps) {
      if (s.action.trim().length < 3) return false;
      if (s.expected.trim().isEmpty) return false;
      if (bannedDataPhrases.any(s.data.toLowerCase().contains)) return false;
    }
    return true;
  }

  String get stepsDisplayString => steps
      .asMap()
      .entries
      .map((e) => '${e.key + 1}. ${e.value.action}')
      .join('\n');

  TestCaseModel copyWith({
    CaseSource? source,
    int? dbId,
    String? id,
    String? title,
    String? module,
    String? feature,
    String? platform,
    String? priority,
    String? type,
    List<String>? preconditions,
    List<TestStep>? steps,
    String? expectedResult,
    String? actualResult,
    String? status,
    ExecutionIntent? intent,
  }) {
    return TestCaseModel(
      source: source ?? this.source,
      dbId: dbId ?? this.dbId,
      id: id ?? this.id,
      title: title ?? this.title,
      module: module ?? this.module,
      feature: feature ?? this.feature,
      platform: platform ?? this.platform,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      preconditions: preconditions ?? List<String>.from(this.preconditions),
      steps:
          steps ??
          this.steps
              .map(
                (s) => TestStep(
                  action: s.action,
                  data: s.data,
                  expected: s.expected,
                ),
              )
              .toList(),
      expectedResult: expectedResult ?? this.expectedResult,
      actualResult: actualResult ?? this.actualResult,
      status: status ?? this.status,
      intent: intent ?? this.intent,
    );
  }

  TestCaseModel copy() => TestCaseModel(
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
          (s) => TestStep(action: s.action, data: s.data, expected: s.expected),
        )
        .toList(),
    expectedResult: expectedResult,
    actualResult: actualResult,
    status: status,
  );

  factory TestCaseModel.fromJson(Map<String, dynamic> j) {
    try {
      List<TestStep> parsedSteps = [];
      final rawSteps = j['steps'];
      if (rawSteps is List) {
        parsedSteps = rawSteps.map((step) {
          try {
            if (step is Map<String, dynamic>) return TestStep.fromJson(step);
            if (step is Map)
              return TestStep.fromJson(Map<String, dynamic>.from(step));
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

      List<String> parsedPreconditions = [];
      final rawPreconditions = j['preconditions'];
      if (rawPreconditions is List) {
        parsedPreconditions = rawPreconditions
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (parsedPreconditions.isEmpty)
        parsedPreconditions = ['Application is accessible and stable'];
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

      final sourceName = (j['source'] ?? 'ai').toString();
      final parsedSource = CaseSource.values.firstWhere(
        (e) => e.name == sourceName,
        orElse: () => CaseSource.ai,
      );

      final intentName = (j['intent'] ?? '').toString();
      ExecutionIntent? parsedIntent;
      try {
        parsedIntent = ExecutionIntent.values.firstWhere(
          (e) => e.name == intentName,
        );
      } catch (_) {
        parsedIntent = null;
      }

      String expectedResult = (j['expectedResult'] ?? '')
          .toString()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (expectedResult.isEmpty)
        expectedResult =
            'System processes the workflow correctly and maintains stable application behavior';

      return TestCaseModel(
        source: parsedSource,
        dbId: j['dbId'] is int ? j['dbId'] as int : null,
        id: (j['id'] ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim(),
        title: (j['title'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),
        module: '',
        feature: '',
        platform: '',
        priority: normalizedPriority,
        type: (j['type'] ?? 'Functional')
            .toString()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),
        preconditions: parsedPreconditions,
        steps: parsedSteps,
        expectedResult: expectedResult,
        actualResult: '',
        status: '',
        intent: parsedIntent,
      );
    } catch (e) {
      throw Exception('TestCaseModel.fromJson failed: $e');
    }
  }

  Map<String, dynamic> toJson() => {
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
    'intent': intent?.name,
  };
}
