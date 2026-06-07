import 'package:flutter/foundation.dart';
import 'package:qa_genie/core/error/exceptions.dart';
import 'package:qa_genie/features/export/writers/file_writer.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';

/// CSV ADAPTER
/// Jira‑compatible CSV export with RFC4180‑safe escaping.
class CsvAdapter {
  const CsvAdapter._();

  static Future<void> export(
    List<FinalizedTestCase> cases, {
    required String fileName,
    required String moduleName,
    required String featureName,
  }) async {
    final startTime = DateTime.now();
    debugPrint('📄 CSV_ADAPTER: Started export for ${cases.length} cases');
    try {
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
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('✅ CSV_ADAPTER: Success in ${duration}ms');
    } catch (e, stack) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('❌ CSV_ADAPTER: Failed after ${duration}ms');
      debugPrint('❌ CSV_ADAPTER error: $e');
      debugPrint('❌ CSV_ADAPTER stack: $stack');
      throw ExportException('CSV export failed: $e');
    }
  }

  static String _escape(String field) {
    return '"${field.replaceAll('\n', ' ').replaceAll('\r', ' ').replaceAll('"', '""')}"';
  }
}
