import 'package:qa_genie/core/error/exceptions.dart';
import 'package:qa_genie/features/export/writers/file_writer.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';
// ============================================================
// FILE: lib/features/export/adapters/csv_adapter.dart
// ============================================================

/// ===============================================================
///
/// CSV ADAPTER
///
/// PURPOSE:
/// - Jira-compatible CSV export
/// - RFC4180-safe escaping
///
/// ARCHITECTURAL ROLE:
/// - Pure reader of FinalizedTestCase.
/// - Guarantees invariant field ordering via ExportMapper.
///
/// ===============================================================
class CsvAdapter {
  const CsvAdapter._();

  // ============================================================
  // EXPORT
  // ============================================================

  static Future<void> export(
    List<FinalizedTestCase> cases, {
    required String fileName,
    required String moduleName,
    required String featureName,
  }) async {
    try {
      /// Forensic logic: Direct consumption of FinalizedTestCase to ensure
      /// session edits (actualResult/status) are reflected instantly.
      final rows = ExportMapper.toJira(cases, featureName: featureName);

      final buffer = StringBuffer();

      for (final row in rows) {
        buffer.writeln(row.map(_escape).join(','));
      }

      await FileWriter.writeAndShare(
        buffer.toString(),
        fileName,
        extension: 'csv',
      );
    } catch (e) {
      throw ExportException('CSV export failed: $e');
    }
  }

  // ============================================================
  // ESCAPE
  // ============================================================

  static String _escape(String field) {
    return '"${field.replaceAll('\n', ' ').replaceAll('\r', ' ').replaceAll('"', '""')}"';
  }
}
