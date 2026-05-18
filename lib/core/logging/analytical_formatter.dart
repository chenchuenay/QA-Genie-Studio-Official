import 'telemetry_snapshot.dart';

class AnalyticalFormatter {
  static String buildAnalyticalDump(TelemetrySnapshot s) {
    final b = StringBuffer();
    final timestamp = s.timestamp.toLocal();
    final tzOffset = timestamp.timeZoneOffset;
    final tzSign = tzOffset.isNegative ? '-' : '+';
    final tzHours = tzOffset.inHours.abs().toString().padLeft(2, '0');
    final tzMinutes = (tzOffset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final tzString = '($tzSign$tzHours:$tzMinutes)';

    b.writeln('[SESSION]');
    b.writeln('id=${s.sessionId}');
    b.writeln('timestamp=${timestamp.toIso8601String()}$tzString');
    b.writeln('mode=${s.mode}');
    b.writeln('provider=${s.provider}');
    b.writeln('model=${s.model}');
    b.writeln('status=${s.sessionCompleted ? "success" : "failure"}');
    b.writeln('duration=${s.totalDurationMs}ms');
    b.writeln();

    b.writeln('[NETWORK]');
    if (s.networkTrace != null) {
      final n = s.networkTrace!;
      b.writeln('status=${n.statusCode}');
      b.writeln('latency=${n.durationMs}ms');
      b.writeln('timeout=${n.statusCode == 408}'); // Simple timeout check
      b.writeln('internet=${n.internetAvailable}');
    } else {
      b.writeln('trace=none');
    }
    b.writeln();

    b.writeln('[PIPELINE]');
    if (s.parserTrace != null) {
      b.writeln('parsed=${s.parserTrace!.parsedCaseCount}');
    } else {
      b.writeln('parsed=0');
    }
    b.writeln('validated=${s.finalCasesJson.length}'); // final count is validated
    b.writeln('repairs=${s.repairedCases}');
    b.writeln('fallback_cases=${s.fallbackGeneratedCases}');
    b.writeln('duplicates_removed=${s.dedupTrace?.duplicatesRemoved ?? 0}');
    b.writeln();

    b.writeln('[FALLBACK]');
    b.writeln('cases=${s.fallbackGeneratedCases}');
    b.writeln('reason=${s.fallbackReason}');
    b.writeln();

    b.writeln('[PERFORMANCE]');
    if (s.performanceTrace != null) {
      final p = s.performanceTrace!;
      b.writeln('prompt_ms=${p.promptBuildMs}ms');
      b.writeln('api_ms=${p.apiCallMs}ms');
      b.writeln('parse_ms=${p.parseMs}ms');
      b.writeln('repair_ms=${p.repairMs}ms');
      b.writeln('total_ms=${p.totalMs}ms');
    } else {
      b.writeln('trace=none');
    }
    b.writeln();

    b.writeln('[TOKENS]');
    b.writeln('prompt=${s.promptTokensEstimate}');
    b.writeln('completion=${s.responseTokensEstimate}');
    b.writeln('total=${s.promptTokensEstimate + s.responseTokensEstimate}');
    b.writeln();

    b.writeln('[ERRORS]');
    b.writeln('provider=${s.errorRegistry.providerErrors}');
    b.writeln('parser=${s.errorRegistry.parserErrors}');
    b.writeln('validator=${s.errorRegistry.validatorErrors}');
    b.writeln('repair=${s.errorRegistry.repairErrors}');
    b.writeln('ui=${s.errorRegistry.uiErrors}');
    b.writeln('export=${s.errorRegistry.exportErrors}');
    b.writeln();

    b.writeln('[STATE]');
    b.writeln(s.stateTransitions.join('→'));
    b.writeln();

    return b.toString();
  }
}
