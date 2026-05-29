import 'dart:convert';
import 'package:qa_genie/engine/forensics/pipeline_audit_logger.dart';

class PipelineAuditReportFormatter {
  const PipelineAuditReportFormatter._();

  static String buildReplayText({
    required String traceId,
    required String module,
    required String feature,
    required String platform,
    required PipelineAuditLogger logger,
    required String rawPrompt,
    required String rawResponse,
    required List<Map<String, dynamic>> parsedCases,
    required List<Map<String, dynamic>> finalizedCases,
  }) {
    final data = logger.toJson();

    final buffer = StringBuffer()
      ..writeln('[QA GENIE END-TO-END FORENSIC REPLAY]')
      ..writeln('')
      ..writeln('=== TRACE ===')
      ..writeln(traceId)
      ..writeln('')
      ..writeln('=== INPUT ===')
      ..writeln('Module: $module')
      ..writeln('Feature: $feature')
      ..writeln('Platform: $platform')
      ..writeln('')
      ..writeln('=== FINAL API PROMPT ===')
      ..writeln(rawPrompt)
      ..writeln('')
      ..writeln('=== RAW AI RESPONSE ===')
      ..writeln(rawResponse)
      ..writeln('')
      ..writeln('=== PARSED TEST CASES ===')
      ..writeln(const JsonEncoder.withIndent('  ').convert(parsedCases))
      ..writeln('')
      ..writeln('=== FINAL OUTPUT ===')
      ..writeln(const JsonEncoder.withIndent('  ').convert(finalizedCases))
      ..writeln('')
      ..writeln('=== VALIDATOR REJECTED ===');

    final rejected = (data['rejectedCases'] as List<dynamic>? ?? []);

    if (rejected.isEmpty) {
      buffer.writeln('NONE');
    } else {
      for (final item in rejected) {
        buffer.writeln(
          '- ${item['title']} '
          '[${item['stage']}] '
          '${item['reason']}',
        );
      }
    }

    buffer
      ..writeln('')
      ..writeln('=== REPAIR LOG ===');

    final repairLog = (data['repairLog'] as List<dynamic>? ?? []);

    if (repairLog.isEmpty) {
      buffer.writeln('NONE');
    } else {
      for (final item in repairLog) {
        buffer.writeln('- $item');
      }
    }

    buffer
      ..writeln('')
      ..writeln('=== FALLBACK TRIGGERS ===');

    final fallback = (data['fallbackTriggers'] as List<dynamic>? ?? []);

    if (fallback.isEmpty) {
      buffer.writeln('NONE');
    } else {
      for (final item in fallback) {
        buffer.writeln('- $item');
      }
    }

    buffer
      ..writeln('')
      ..writeln('=== PIPELINE METRICS ===')
      ..writeln(
        'Average Confidence: '
        '${(data['averageConfidence'] ?? 0).toString()}',
      )
      ..writeln('')
      ..writeln('=== DIVERSITY BALANCE ===')
      ..writeln(
        const JsonEncoder.withIndent('  ').convert(data['diversityBalance']),
      )
      ..writeln('')
      ..writeln('=== LINEAGE BALANCE ===')
      ..writeln(
        const JsonEncoder.withIndent('  ').convert(data['lineageBalance']),
      )
      ..writeln('')
      ..writeln('=== SECURITY EVENTS ===');

    final security = (data['securityEvents'] as List<dynamic>? ?? []);

    if (security.isEmpty) {
      buffer.writeln('NONE');
    } else {
      for (final item in security) {
        buffer.writeln('- $item');
      }
    }

    buffer
      ..writeln('')
      ..writeln('=== TIMELINE ===');

    final timeline = (data['timeline'] as List<dynamic>? ?? []);

    if (timeline.isEmpty) {
      buffer.writeln('NONE');
    } else {
      for (final item in timeline) {
        buffer.writeln(item.toString());
      }
    }

    return buffer.toString();
  }
}
