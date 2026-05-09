import 'package:qa_app/core/utils/priority_utils.dart';
import 'package:qa_app/data/models/test_case_model.dart';

class ExportMapper {
  static String _expectedResult(TestCaseModel tc) {
    if (tc.expectedResult.trim().isNotEmpty) return tc.expectedResult;
    if (tc.steps.isNotEmpty && tc.steps.last.expected.trim().isNotEmpty) {
      return tc.steps.last.expected;
    }
    return 'No expected result provided';
  }

  static List<List<String>> toExcel(
    List<TestCaseModel> cases, {
    String moduleName = '',
    String featureName = '',
  }) {
    final rows = <List<String>>[];
    rows.add([
      "Test Case ID",
      "Module",
      "Feature",
      "Test Case Title",
      "Preconditions",
      "Test Data",
      "Test Steps",
      "Expected Result",
      "Actual Result",
      "Status",
      "Priority",
    ]);
    for (var tc in cases) {
      final stepsOnly = tc.steps
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${e.value.action}')
          .join('\n');
      final allData = tc.steps
          .map((s) => s.data)
          .where((d) => d.isNotEmpty)
          .join('\n');
      rows.add([
        tc.id,
        tc.module.isNotEmpty ? tc.module : moduleName,
        tc.feature.isNotEmpty ? tc.feature : featureName,
        tc.title,
        tc.preconditions.join('; '),
        allData,
        stepsOnly,
        _expectedResult(tc),
        tc.actualResult,
        tc.status.isEmpty ? 'Not Executed' : tc.status.toUpperCase(),
        PriorityUtils.normalize(tc.priority).toUpperCase(),
      ]);
    }
    return rows;
  }

  static List<List<String>> toJira(
    List<TestCaseModel> cases, {
    String featureName = '',
  }) {
    final rows = <List<String>>[];
    rows.add([
      "Summary",
      "Issue Type",
      "Description",
      "Preconditions",
      "Test Steps",
      "Expected Result",
      "Priority",
      "Status",
    ]);
    for (var tc in cases) {
      final stepsDesc = tc.steps
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${e.value.action}')
          .join('\n');
      final feat = tc.feature.isNotEmpty ? tc.feature : featureName;
      rows.add([
        tc.title,
        "Test",
        feat,
        tc.preconditions.join('; '),
        stepsDesc,
        _expectedResult(tc),
        PriorityUtils.normalize(tc.priority).toUpperCase(),
        tc.status.isEmpty ? 'To Do' : tc.status.toUpperCase(),
      ]);
    }
    return rows;
  }

  static List<Map<String, dynamic>> toXray(
    List<TestCaseModel> cases, {
    String moduleName = '',
    String featureName = '',
  }) {
    return cases.map((tc) {
      final feat = tc.feature.isNotEmpty ? tc.feature : featureName;
      return {
        "issueId": tc.id,
        "summary": tc.title,
        "testType": "Manual",
        "description": feat,
        "precondition": tc.preconditions.join('; '),
        "priority": PriorityUtils.normalize(tc.priority).toUpperCase(),
        "status": tc.status.isEmpty ? 'NOT EXECUTED' : tc.status.toUpperCase(),
        "steps": tc.steps
            .asMap()
            .entries
            .map(
              (e) => {
                "step": e.key + 1,
                "action": e.value.action,
                "data": e.value.data,
                "result": e.value.expected,
              },
            )
            .toList(),
      };
    }).toList();
  }

  static List<Map<String, dynamic>> toPdf(List<TestCaseModel> cases) {
    return cases
        .map(
          (tc) => {
            "ID": tc.id,
            "Title": tc.title,
            "Preconditions": tc.preconditions.join('; '),
            "Steps": tc.steps
                .asMap()
                .entries
                .map((e) => '${e.key + 1}. ${e.value.action}')
                .join('\n'),
            "Test Data": tc.steps
                .map((s) => s.data)
                .where((d) => d.isNotEmpty)
                .join('\n'),
            "Expected Result": _expectedResult(tc),
            "Priority": PriorityUtils.normalize(tc.priority).toUpperCase(),
            "Actual": tc.actualResult,
            "Status": tc.status.isEmpty
                ? 'Not Executed'
                : tc.status.toUpperCase(),
          },
        )
        .toList();
  }

  static Map<String, dynamic> toSummaryReport(
    List<TestCaseModel> cases,
    String moduleName,
    String featureName,
    String platform,
    String testerName,
    String environment,
  ) {
    final total = cases.length;
    final passed = cases.where((c) => c.status.toUpperCase() == 'PASS').length;
    final failed = cases.where((c) => c.status.toUpperCase() == 'FAIL').length;
    final blocked = cases
        .where((c) => c.status.toUpperCase() == 'BLOCKED')
        .length;
    final notExecuted = cases
        .where(
          (c) => c.status.toUpperCase() == 'NOT EXECUTED' || c.status.isEmpty,
        )
        .length;
    final executed = passed + failed + blocked;
    final passRate = executed > 0
        ? (passed / executed * 100).toStringAsFixed(1)
        : '0.0';

    String priorityBreakdown(String p, Iterable<TestCaseModel> list) {
      if (list.isEmpty) return '$p: 0';
      final pCount = list.where((c) => c.status.toUpperCase() == 'PASS').length;
      final fCount = list.where((c) => c.status.toUpperCase() == 'FAIL').length;
      final bCount = list
          .where((c) => c.status.toUpperCase() == 'BLOCKED')
          .length;
      final nCount = list
          .where(
            (c) => c.status.toUpperCase() == 'NOT EXECUTED' || c.status.isEmpty,
          )
          .length;
      return '$p: ${list.length} ($pCount Passed, $fCount Failed, $bCount Blocked, $nCount Not Executed)';
    }

    return {
      'suiteName': '$moduleName · $featureName',
      'platform': platform,
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'testerName': testerName,
      'environment': environment,
      'total': total,
      'passed': passed,
      'failed': failed,
      'blocked': blocked,
      'notExecuted': notExecuted,
      'passRate': passRate,
      'priorityBreakdown': [
        priorityBreakdown(
          'High',
          cases.where((c) => c.priority.toUpperCase() == 'HIGH'),
        ),
        priorityBreakdown(
          'Medium',
          cases.where((c) => c.priority.toUpperCase() == 'MEDIUM'),
        ),
        priorityBreakdown(
          'Low',
          cases.where((c) => c.priority.toUpperCase() == 'LOW'),
        ),
      ],
      'details': cases
          .map(
            (tc) => {
              'id': tc.id,
              'title': tc.title,
              'priority': PriorityUtils.normalize(tc.priority).toUpperCase(),
              'status': tc.status.isEmpty
                  ? 'NOT EXECUTED'
                  : tc.status.toUpperCase(),
              'actualResult': tc.actualResult,
              'expectedResult': tc.expectedResult,
            },
          )
          .toList(),
    };
  }
}
