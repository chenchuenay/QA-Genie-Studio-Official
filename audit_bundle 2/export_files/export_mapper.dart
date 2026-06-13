import 'package:qa_genie/core/utils/priority_utils.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

// ============================================================
// FILE: lib/features/export/common/export_mapper.dart
// ============================================================

/// ===============================================================
///
/// EXPORT MAPPER
///
/// PURPOSE:
/// - Single export normalization layer
/// - Keeps all adapters deterministic
/// - Guarantees schema-safe exports
/// - Prevents adapter-level business logic duplication
///
/// SUPPORTED:
/// - Excel (.xlsx)
/// - Jira (.csv)
/// - Xray (.json)
/// - PDF (traditional QA table format)
///
/// IMPORTANT:
/// - ALL export adapters MUST consume mapped output ONLY
/// - No adapter should directly mutate FinalizedTestCase
/// - Forensic lineage (AI/FB/REP) MUST NEVER be mapped for export.
///
/// ===============================================================
class ExportMapper {
  const ExportMapper._();

  // ============================================================
  // COMMON HELPERS
  // ============================================================

  static String safe(String? value) {
    if (value == null) return '';
    return value
        .replaceAll('\r', ' ')
        .replaceAll('\t', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _expectedResult(FinalizedTestCase tc) {
    final expected = safe(tc.expectedResult);
    if (expected.isNotEmpty) return expected;
    if (tc.steps.isNotEmpty) {
      final last = safe(tc.steps.last.expected);
      if (last.isNotEmpty) return last;
    }
    return 'Expected behavior is observed.';
  }

  static String _status(String status) {
    final normalized = safe(status).toUpperCase();
    return normalized.isEmpty ? 'NOT EXECUTED' : normalized;
  }

  static String _priority(String priority) {
    return PriorityUtils.normalize(priority).toUpperCase();
  }

  static String _stepsOnly(FinalizedTestCase tc) {
    return tc.steps
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${safe(e.value.action)}')
        .join('\n');
  }

  static List<Map<String, String>> _xraySteps(FinalizedTestCase tc) {
    return tc.steps.asMap().entries.map((e) {
      return {
        'step': '${e.key + 1}',
        'action': safe(e.value.action),
        'data': safe(e.value.data),
        'result': safe(e.value.expected),
      };
    }).toList();
  }

  // ============================================================
  // EXCEL (.XLSX)
  // ============================================================

  static List<List<String>> toExcel(
    List<FinalizedTestCase> cases, {
    String moduleName = '',
    String featureName = '',
  }) {
    final rows = <List<String>>[];
    rows.add([
      'Test Case ID',
      'Module',
      'Feature',
      'Test Case Title',
      'Preconditions',
      'Test Data',
      'Test Steps',
      'Expected Result',
      'Actual Result',
      'Status',
      'Priority',
    ]);

    for (final tc in cases) {
      rows.add([
        safe(tc.id),
        safe(tc.module.isNotEmpty ? tc.module : moduleName),
        safe(tc.feature.isNotEmpty ? tc.feature : featureName),
        safe(tc.title),
        tc.preconditions.map(safe).join('; '),
        safe(tc.testData),
        _stepsOnly(tc),
        _expectedResult(tc),
        safe(tc.actualResult),
        _status(tc.status),
        _priority(tc.priority),
      ]);
    }
    return rows;
  }

  // ============================================================
  // JIRA (.CSV)
  // ============================================================

  static List<List<String>> toJira(
    List<FinalizedTestCase> cases, {
    String featureName = '',
  }) {
    final rows = <List<String>>[];
    rows.add([
      'Summary',
      'Issue Type',
      'Description',
      'Preconditions',
      'Test Steps',
      'Expected Result',
      'Priority',
      'Status',
    ]);

    for (final tc in cases) {
      final feature = tc.feature.isNotEmpty ? tc.feature : featureName;
      rows.add([
        safe(tc.title),
        'Test',
        safe(feature),
        tc.preconditions.map(safe).join('; '),
        _stepsOnly(tc),
        _expectedResult(tc),
        _priority(tc.priority),
        _status(tc.status),
      ]);
    }
    return rows;
  }

  // ============================================================
  // XRAY (.JSON)
  // ============================================================

  static List<Map<String, dynamic>> toXray(
    List<FinalizedTestCase> cases, {
    String moduleName = '',
    String featureName = '',
  }) {
    return cases.map((tc) {
      final feature = tc.feature.isNotEmpty ? tc.feature : featureName;
      return {
        'issueId': safe(tc.id),
        'summary': safe(tc.title),
        'testType': 'Manual',
        'description': safe(feature),
        'module': safe(tc.module.isNotEmpty ? tc.module : moduleName),
        'precondition': tc.preconditions.map(safe).join('; '),
        'priority': _priority(tc.priority),
        'status': _status(tc.status),
        'steps': _xraySteps(tc),
      };
    }).toList();
  }

  // ============================================================
  // PDF (traditional QA table format)
  // ============================================================

  static List<Map<String, dynamic>> toPdf(List<FinalizedTestCase> cases) {
    return cases.map((tc) {
      return {
        'Test Case ID': safe(tc.id), // Changed from 'ID' to 'Test Case ID'
        'Title': safe(tc.title),
        'Preconditions': tc.preconditions.map(safe).join('; '),
        'Steps': _stepsOnly(tc),
        'Test Data': safe(tc.testData),
        'Expected Result': _expectedResult(tc),
        'Actual Result': safe(tc.actualResult),
        'Priority': _priority(tc.priority),
        'Status': _status(tc.status),
      };
    }).toList();
  }

  // ============================================================
  // SUMMARY REPORT
  // ============================================================

  static Map<String, dynamic> toSummaryReport(
    List<FinalizedTestCase> cases,
    String moduleName,
    String featureName,
    String platform,
    String testerName,
    String environment,
  ) {
    final total = cases.length;
    final passed = cases.where((c) => _status(c.status) == 'PASS').length;
    final failed = cases.where((c) => _status(c.status) == 'FAIL').length;
    final blocked = cases.where((c) => _status(c.status) == 'BLOCKED').length;
    final notExecuted = cases
        .where((c) => _status(c.status) == 'NOT EXECUTED')
        .length;
    final executed = passed + failed + blocked;
    final passRate = executed == 0
        ? '0.0'
        : ((passed / executed) * 100).toStringAsFixed(1);

    return {
      'suiteName': '$moduleName · $featureName',
      'platform': safe(platform),
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'testerName': safe(testerName),
      'environment': safe(environment),
      'total': total,
      'passed': passed,
      'failed': failed,
      'blocked': blocked,
      'notExecuted': notExecuted,
      'passRate': passRate,
      'priorityBreakdown': {
        'HIGH': cases.where((c) => _priority(c.priority) == 'HIGH').length,
        'MEDIUM': cases.where((c) => _priority(c.priority) == 'MEDIUM').length,
        'LOW': cases.where((c) => _priority(c.priority) == 'LOW').length,
      },
      'details': cases.map((tc) {
        return {
          'id': safe(tc.id),
          'title': safe(tc.title),
          'priority': _priority(tc.priority),
          'status': _status(tc.status),
          'expectedResult': _expectedResult(tc),
          'actualResult': safe(tc.actualResult),
        };
      }).toList(),
    };
  }
}
