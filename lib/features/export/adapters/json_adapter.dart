import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:qa_genie/core/error/exceptions.dart';
import 'package:qa_genie/features/export/writers/file_writer.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/export/common/export_mapper.dart';

/// JSON ADAPTER
/// Xray‑compatible JSON export.
class JsonAdapter {
  const JsonAdapter._();

  static Future<void> export(
    List<FinalizedTestCase> cases, {
    required String fileName,
    required String moduleName,
    required String featureName,
  }) async {
    final startTime = DateTime.now();
    debugPrint('📦 JSON_ADAPTER: Started export for ${cases.length} cases');
    try {
      final data = ExportMapper.toXray(
        cases,
        moduleName: moduleName,
        featureName: featureName,
      );
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await FileWriter.writeAndShare(jsonString, fileName, extension: 'json');
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('✅ JSON_ADAPTER: Success in ${duration}ms');
    } catch (e, stack) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('❌ JSON_ADAPTER: Failed after ${duration}ms');
      debugPrint('❌ JSON_ADAPTER error: $e');
      debugPrint('❌ JSON_ADAPTER stack: $stack');
      throw ExportException('JSON export failed: $e');
    }
  }
}
