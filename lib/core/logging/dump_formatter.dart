import 'telemetry_snapshot.dart';

class DumpFormatter {
  static String buildPipelineDump(TelemetrySnapshot snapshot) {
    final buf = StringBuffer();
    final sep = '=' * 72;
    
    buf.writeln(sep);
    buf.writeln('SESSION START');
    buf.writeln('timestamp: ${DateTime.now().toIso8601String()}');
    buf.writeln('session_id: ${DateTime.now().millisecondsSinceEpoch}');
    buf.writeln('build_mode: debug');
    buf.writeln('generation_mode: ${snapshot.sessionMode.toUpperCase()}');
    buf.writeln('provider: ${snapshot.provider}');
    buf.writeln('model: ${snapshot.model}');
    buf.writeln(sep);
    
    buf.writeln('\n=== REQUEST METADATA ===');
    buf.writeln('timestamp: ${DateTime.now().toIso8601String()}');
    buf.writeln('session_id: ${DateTime.now().millisecondsSinceEpoch}');
    buf.writeln('build_mode: debug');
    buf.writeln('generation_mode: ${snapshot.sessionMode.toUpperCase()}');
    buf.writeln('provider: ${snapshot.provider}');
    buf.writeln('model: ${snapshot.model}');
    buf.writeln('timeout_ms: ${snapshot.timeoutMs}');
    buf.writeln('retry_count: ${snapshot.retryCount}');
    buf.writeln('constraints_length: 0');
    buf.writeln('prompt_characters: ${snapshot.promptChars}');
    buf.writeln('estimated_prompt_tokens: ${(snapshot.promptChars / 4).ceil()}');
    buf.writeln('requested_testcase_count: ${snapshot.requestedCount}');
    
    buf.writeln('\n=== PERFORMANCE TRACE ===');
    buf.writeln('total_generation_ms: ${snapshot.totalMs}');
    buf.writeln('prompt_build_ms: ${snapshot.promptBuildMs}');
    buf.writeln('api_call_ms: ${snapshot.apiCallMs}');
    buf.writeln('parse_ms: ${snapshot.parseMs}');
    buf.writeln('validation_ms: ${snapshot.validationMs}');
    buf.writeln('repair_ms: ${snapshot.repairMs}');
    
    buf.writeln('\n=== (other sections will be added in later phases) ===');
    
    buf.writeln(sep);
    buf.writeln('SESSION END');
    buf.writeln('duration_ms: ${snapshot.totalMs}');
    buf.writeln('final_status: success');
    buf.writeln(sep);
    
    return buf.toString();
  }
}
