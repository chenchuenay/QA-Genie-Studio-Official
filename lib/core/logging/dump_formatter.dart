import 'dart:convert';
import 'telemetry_snapshot.dart';

class DumpFormatter {
  static const int maxRawChars = 50000;

  static String buildPipelineDump(TelemetrySnapshot s) {
    final b = StringBuffer();

    // HEADER
    b.writeln('FILE_SCHEMA_VERSION=1');
    b.writeln('ENCODING=UTF-8');
    b.writeln('FORENSIC_MODE=${s.forensicMode}');
    b.writeln('BUILD_MODE=${s.buildMode}');
    b.writeln('APP_VERSION=${s.appVersion}');
    b.writeln('BUILD_NUMBER=${s.buildNumber}');
    b.writeln();

    // SESSION HEADER
    b.writeln('==================================================');
    b.writeln('SESSION HEADER');
    b.writeln('session_id=${s.sessionId}');
    b.writeln('timestamp=${s.timestamp.toIso8601String()}');
    b.writeln('provider=${s.provider}');
    b.writeln('model=${s.model}');
    b.writeln('mode=${s.mode}');
    b.writeln('thread=main');
    b.writeln('logging_schema_version=1');
    b.writeln('==================================================');
    b.writeln();

    // SYSTEM SNAPSHOT
    b.writeln('=== SYSTEM SNAPSHOT ===');
    b.writeln('os=${s.os}');
    b.writeln('device=${s.device}');
    b.writeln('locale=${s.locale}');
    b.writeln('timezone=${s.timezone}');
    b.writeln('flutter_version=${s.flutterVersion}');
    b.writeln('dart_version=${s.dartVersion}');
    b.writeln();

    // USER INPUT
    b.writeln('=== USER INPUT ===');
    b.writeln('module=${s.module}');
    b.writeln('feature=${s.feature}');
    b.writeln('platform=${s.platform}');
    b.writeln('constraints=${s.constraints}');
    b.writeln('requested_case_count=${s.requestedCount}');
    b.writeln('prompt_characters=${s.prompt.length}');
    b.writeln('prompt_tokens_estimate=${s.promptTokensEstimate}');
    b.writeln();

    // FULL PROMPT
    b.writeln('=== FULL PROMPT ===');
    b.writeln(s.prompt);
    b.writeln();

    // NETWORK TRACE
    b.writeln('=== NETWORK TRACE ===');
    if (s.networkTrace != null) {
      final n = s.networkTrace!;
      b.writeln('status=${n.statusCode}');
      b.writeln('latency=${n.durationMs}');
      b.writeln('retry_count=${n.retryCount}');
      b.writeln('internet=${n.internetAvailable}');
      b.writeln('timeout=${n.statusCode == 408}');
      b.writeln('provider_error=${n.errorMessage ?? "none"}');
    } else {
      b.writeln('No network trace.');
    }
    b.writeln();

    // RAW AI RESPONSE
    b.writeln('=== RAW AI RESPONSE ===');
    final raw = s.rawResponse;
    final truncated = raw.length > maxRawChars;
    final safeRaw = truncated ? raw.substring(0, maxRawChars) : raw;
    b.writeln('raw_response_original_size=${raw.length}');
    b.writeln('raw_response_stored_size=${safeRaw.length}');
    b.writeln('truncated=$truncated');
    b.writeln(safeRaw);
    b.writeln();

    // PARSER ANALYSIS
    b.writeln('=== PARSER ANALYSIS ===');
    if (s.parserTrace != null) {
      final p = s.parserTrace!;
      b.writeln('parse_success=${p.parseSuccess}');
      b.writeln('parsed_case_count=${p.parsedCaseCount}');
      b.writeln('malformed_blocks=${p.malformedBlocks}');
      b.writeln('json_failures=${p.parserFailures.length}');
    } else {
      b.writeln('No parser trace.');
    }
    b.writeln();

    // VALIDATOR ANALYSIS
    b.writeln('=== VALIDATOR ANALYSIS ===');
    if (s.validatorTraces.isEmpty) {
      b.writeln('No validator rejections.');
    } else {
      for (final v in s.validatorTraces) {
        b.writeln('----------------------------------------');
        b.writeln('test_case_id=${v.testCaseId}');
        b.writeln('title=${v.title}');
        b.writeln('failed_rules=${v.failedRules.join(",")}');
        b.writeln('quality_score=${v.qualityScore}');
      }
    }
    b.writeln();

    // DEDUP TRACE
    b.writeln('=== DEDUP TRACE ===');
    final d = s.dedupTrace;
    if (d != null) {
      b.writeln('ai_input_count=${d.aiInputCount}');
      b.writeln('duplicates_removed=${d.duplicatesRemoved}');
      b.writeln('fallback_generated_count=${d.fallbackGeneratedCount}');
      b.writeln('final_output_count=${d.finalOutputCount}');
    } else {
      b.writeln('No dedup trace.');
    }
    b.writeln();

    // REPAIR TRACE
    b.writeln('=== REPAIR TRACE ===');
    b.writeln('repaired_cases=${s.repairedCases}');
    if (s.repairTraces.isEmpty) {
      b.writeln('No detailed repair traces.');
    } else {
      for (final r in s.repairTraces) {
        b.writeln('----------------------------------------');
        b.writeln('testcase_id=${r.testCaseId}');
        b.writeln('changed_field=${r.changedField}');
        b.writeln('before=${r.before}');
        b.writeln('after=${r.after}');
        b.writeln('reason=${r.reason}');
        b.writeln('success=${r.success}');
      }
    }
    b.writeln();

    // FALLBACK TRACE
    b.writeln('=== FALLBACK TRACE ===');
    if (s.fallbackGeneratedCases > 0) {
      b.writeln('fallback_triggered=true');
      b.writeln('fallback_reason=${s.fallbackReason}');
      b.writeln('fallback_generated_cases=${s.fallbackGeneratedCases}');
    } else {
      b.writeln('fallback_triggered=false');
    }
    b.writeln();

    // FINAL OUTPUT
    b.writeln('=== FINAL OUTPUT ===');
    b.writeln(const JsonEncoder.withIndent('  ').convert(s.finalCasesJson));
    b.writeln();

    // PERFORMANCE TRACE
    b.writeln('=== PERFORMANCE TRACE ===');
    if (s.performanceTrace != null) {
      final p = s.performanceTrace!;
      b.writeln('prompt_build_ms=${p.promptBuildMs}');
      b.writeln('api_call_ms=${p.apiCallMs}');
      b.writeln('parse_ms=${p.parseMs}');
      b.writeln('repair_ms=${p.repairMs}');
      b.writeln('fallback_ms=${p.fallbackMs}');
      b.writeln('total_ms=${p.totalMs}');
    } else {
      b.writeln('No performance trace.');
    }
    b.writeln();

    // TOKEN ANALYTICS
    b.writeln('=== TOKEN ANALYTICS ===');
    b.writeln('prompt_tokens_estimate=${s.promptTokensEstimate}');
    b.writeln('completion_tokens_estimate=${s.responseTokensEstimate}');
    b.writeln('total_tokens=${s.promptTokensEstimate + s.responseTokensEstimate}');
    b.writeln();

    // UI ERRORS
    b.writeln('=== UI ERRORS ===');
    if (s.uiErrorTraces.isEmpty) {
      b.writeln('No UI errors.');
    } else {
      for (final e in s.uiErrorTraces) {
        b.writeln('----------------------------------------');
        b.writeln('timestamp=${e.timestamp}');
        b.writeln('screen=${e.screen}');
        b.writeln('user_message=${e.userMessage}');
        b.writeln('technical_error=${e.technicalError}');
        b.writeln('stacktrace=${e.stackTrace ?? "none"}');
      }
    }
    b.writeln();

    // GLOBAL ERROR CLASSIFICATION
    b.writeln('=== GLOBAL ERROR CLASSIFICATION ===');
    b.writeln('provider_errors=${s.errorRegistry.providerErrors}');
    b.writeln('parser_errors=${s.errorRegistry.parserErrors}');
    b.writeln('validator_errors=${s.errorRegistry.validatorErrors}');
    b.writeln('repair_errors=${s.errorRegistry.repairErrors}');
    b.writeln('export_errors=${s.errorRegistry.exportErrors}');
    b.writeln('ui_errors=${s.errorRegistry.uiErrors}');
    b.writeln();

    // SESSION FOOTER
    b.writeln('=== SESSION FOOTER ===');
    b.writeln('final_status=${s.sessionCompleted ? "completed" : "failed"}');
    b.writeln('session_integrity_hash=${s.integrityHash}');
    b.writeln('duration_ms=${s.totalDurationMs}');
    b.writeln('session_completed=${s.sessionCompleted}');
    b.writeln();

    return b.toString();
  }
}
