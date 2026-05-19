import 'package:qa_genie/core/debug/pipeline_debug_store.dart';
import 'package:qa_genie/core/logging/telemetry_snapshot.dart';
import 'package:qa_genie/data/datasources/remote/generation_api.dart';

class DumpFormatter {
  static String build(TelemetrySnapshot s) {
    final b = StringBuffer();

    b.writeln('==============================');
    b.writeln('QA GENIE PIPELINE FORENSICS');
    b.writeln('==============================');

    b.writeln('');
    b.writeln('=== REQUEST METADATA ===');

    b.writeln('provider=${PipelineDebugStore.lastProvider}');
    b.writeln('prompt_characters=${s.prompt.length}');
    b.writeln('prompt_tokens_estimate=${s.promptTokensEstimate}');
    b.writeln('response_tokens_estimate=${s.responseTokensEstimate}');

    b.writeln('');
    b.writeln('=== NETWORK TRACE ===');

    b.writeln('status_code=${NetworkTraceStore.lastStatusCode}');

    b.writeln('duration_ms=${NetworkTraceStore.lastDurationMs}');

    b.writeln('error_message=${NetworkTraceStore.lastErrorMessage ?? "none"}');

    b.writeln('');
    b.writeln('=== PIPELINE STATS ===');

    b.writeln('parsed_objects=${PipelineDebugStore.lastParsedCount}');

    b.writeln('recovered_objects=${PipelineDebugStore.recoveredObjectCount}');

    b.writeln('rejected_objects=${PipelineDebugStore.rejectedObjectCount}');

    b.writeln(
      'malformed_skipped=${PipelineDebugStore.malformedObjectsSkipped}',
    );

    b.writeln(
      'partial_recovery_used=${PipelineDebugStore.partialRecoveryUsed}',
    );

    b.writeln('');
    b.writeln('=== PERFORMANCE ===');

    if (s.performanceTrace != null) {
      final p = s.performanceTrace!;

      b.writeln('prompt_build_ms=${p.promptBuildMs}');

      b.writeln('api_call_ms=${p.apiCallMs}');

      b.writeln('parse_ms=${p.parseMs}');

      b.writeln('validation_ms=${p.validationMs}');

      b.writeln('repair_ms=${p.repairMs}');

      b.writeln('fallback_ms=${p.fallbackMs}');

      b.writeln('total_ms=${p.totalMs}');
    }

    b.writeln('');
    b.writeln('=== FINAL PROMPT ===');
    b.writeln(s.prompt);

    b.writeln('');
    b.writeln('=== RAW RESPONSE ===');

    final raw = PipelineDebugStore.lastRawResponse;

    if (raw.isEmpty) {
      b.writeln('[EMPTY]');
    } else {
      final safe = raw.length > 50000 ? raw.substring(0, 50000) : raw;

      b.writeln(safe);
    }

    b.writeln('');
    b.writeln('=== CLEANED RESPONSE ===');

    final cleaned = PipelineDebugStore.lastCleanedResponse;

    if (cleaned.isEmpty) {
      b.writeln('[EMPTY]');
    } else {
      final safe = cleaned.length > 50000
          ? cleaned.substring(0, 50000)
          : cleaned;

      b.writeln(safe);
    }

    b.writeln('');
    b.writeln('==============================');

    return b.toString();
  }
}
