import 'dart:convert';
import 'package:qa_genie/core/error/exceptions.dart';
import 'package:qa_genie/features/export/writers/file_writer.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';

// ============================================================
// FILE: lib/features/export/adapters/json_adapter.dart
// ============================================================

/// ===============================================================
///
/// JSON ADAPTER
///
/// PURPOSE:
/// - Xray-compatible export
/// - Deterministic schema-safe JSON
///
/// ARCHITECTURAL ROLE:
/// - Pure reader of FinalizedTestCase.
/// - Guarantees invariant field ordering via ExportMapper.
///
/// ===============================================================
class JsonAdapter {
  const JsonAdapter._();

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
      final data = ExportMapper.toXray(
        cases,
        moduleName: moduleName,
        featureName: featureName,
      );

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      await FileWriter.writeAndShare(jsonString, fileName, extension: 'json');
    } catch (e) {
      throw ExportException('JSON export failed: $e');
    }
  }
}
