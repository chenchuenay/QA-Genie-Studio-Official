import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:qa_genie/data/models/test_case_model.dart';

enum PipelineMode { core, pro }

class AcceptanceReason {
  final String title;
  final List<String> reasons;
  AcceptanceReason(this.title, this.reasons);
}

class RejectionReason {
  final String title;
  final List<String> reasons;
  RejectionReason(this.title, this.reasons);
}

class DuplicateCluster {
  final List<String> titles;
  final String reason;
  DuplicateCluster(this.titles, this.reason);
}

class RepairTransform {
  final String before;
  final String after;
  final List<String> actions;
  RepairTransform(this.before, this.after, this.actions);
}

class PipelineLogger {
  final StringBuffer _buf = StringBuffer();
  final PipelineMode _mode;
  final Stopwatch _stopwatch = Stopwatch();
  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final DateTime createdAt = DateTime.now();

  String module = '', feature = '', platform = '', constraints = '';
  int requestedCount = 0;
  String basePrompt = '';
  String finalApiPrompt = '';
  String rawAiResponse = '';
  String cleanedAiResponse = '';
  List<String> parseFailures = [];
  List<TestCaseModel> parsedCases = [];
  List<TestCaseModel> acceptedCases = [];
  List<AcceptanceReason> acceptedReasons = [];
  List<RejectionReason> rejectedCases = [];
  List<DuplicateCluster> duplicateClusters = [];
  List<TestCaseModel> afterDedup = [];
  List<RepairTransform> repairTransforms = [];
  List<TestCaseModel> afterRepair = [];
  List<TestCaseModel> finalCases = [];
  int aiGenerated = 0;
  int accepted = 0;
  int repaired = 0;
  int filtered = 0;
  int duplicatesRemoved = 0;
  bool fallbackUsed = false;
  int generationTimeMs = 0;
  bool aiFailure = false;
  int promptTokensEstimate = 0;
  int responseTokensEstimate = 0;

  PipelineLogger(this._mode) {
    _stopwatch.start();
  }

  void recordParseFailure(String reason) { parseFailures.add(reason); }

  void recordRejection(String title, String reason) {
    for (final r in rejectedCases) {
      if (r.title == title) { r.reasons.add(reason); return; }
    }
    rejectedCases.add(RejectionReason(title, [reason]));
  }

  void recordAcceptance(String title, String reason) {
    for (final a in acceptedReasons) {
      if (a.title == title) { a.reasons.add(reason); return; }
    }
    acceptedReasons.add(AcceptanceReason(title, [reason]));
  }

  void recordDuplicateCluster(List<String> titles, String reason) {
    duplicateClusters.add(DuplicateCluster([...titles], reason));
  }

  void recordRepairTransform(String before, String after, List<String> actions) {
    repairTransforms.add(RepairTransform(before, after, actions));
  }

  void finalize() {
    _stopwatch.stop();
    generationTimeMs = _stopwatch.elapsedMilliseconds;
    promptTokensEstimate = (finalApiPrompt.length / 4).ceil();
    responseTokensEstimate = (rawAiResponse.length / 4).ceil();
  }

  Future<void> writeToDisk() async {
    finalize();
    // Guaranteed writable path on Android
    final debugDir = Directory('/data/data/com.enaykumar.qagenie/cache/test_results');
    if (!debugDir.existsSync()) {
      debugDir.createSync(recursive: true);
    }
    final fileName = _mode == PipelineMode.core ? 'core_pipeline.txt' : 'pro_pipeline.txt';
    final file = File('${debugDir.path}/$fileName');
    _buildDump();
    await file.writeAsString(_buf.toString(), mode: FileMode.write);
    print('[PIPELINE LOG] Written to ${file.path}');
  }

  String _safe(String? value, [int max = 300]) {
    if (value == null || value.trim().isEmpty) return '[EMPTY]';
    return value.length > max ? '${value.substring(0, max)}...' : value;
  }

  String _cap(String value, int maxChars) {
    if (value.length > maxChars) {
      return '${value.substring(0, maxChars)}... [TRUNCATED at $maxChars characters]';
    }
    return value;
  }

  void _buildDump() {
    _buf.clear();
    final sep = '=' * 72;
    _buf.writeln(sep);
    final buildMode = kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug');
    _buf.writeln('MODE: ${_mode == PipelineMode.core ? 'CORE' : 'PRO'}');
    _buf.writeln('session_id: $sessionId');
    _buf.writeln('generated_at: $createdAt');
    _buf.writeln('build_mode: $buildMode');
    _buf.writeln(sep);
    _buf.writeln('\n=== INPUT ===');
    _buf.writeln('module: $module');
    _buf.writeln('feature: $feature');
    _buf.writeln('platform: $platform');
    _buf.writeln('constraints: $constraints');
    _buf.writeln('requested_count: $requestedCount');
    _buf.writeln('\n=== BASE PROMPT ===');
    _buf.writeln(_cap(basePrompt, 30000));
    _buf.writeln('\n=== FINAL API PROMPT ===');
    _buf.writeln(_cap(finalApiPrompt, 30000));
    _buf.writeln('\n=== RAW AI RESPONSE ===');
    _buf.writeln(_cap(rawAiResponse, 50000));
    _buf.writeln('\n=== CLEANED AI RESPONSE ===');
    _buf.writeln(_cap(cleanedAiResponse, 50000));
    if (parseFailures.isNotEmpty) {
      _buf.writeln('\n=== PARSE FAILURES ===');
      for (final f in parseFailures) { _buf.writeln('- $f'); }
    }
    _buf.writeln('\n=== PARSED TEST CASES ===');
    _buf.writeln('generated_count: ${parsedCases.length}');
    for (var i = 0; i < parsedCases.length; i++) {
      final tc = parsedCases[i];
      _buf.writeln('${i + 1}. ${tc.title}');
      _buf.writeln('   Steps: ${tc.steps.length}');
      _buf.writeln('   Priority: ${tc.priority}');
      _buf.writeln('   Expected: ${_safe(tc.expectedResult, 80)}');
    }
    _buf.writeln('\n=== VALIDATOR ACCEPTED ===');
    _buf.writeln('accepted_count: ${acceptedCases.length}');
    for (final tc in acceptedCases) {
      _buf.writeln('- ${tc.title}');
      _buf.writeln('  Acceptance reasons:');
      for (final a in acceptedReasons.where((a) => a.title == tc.title)) {
        for (final r in a.reasons) { _buf.writeln('    - $r'); }
      }
    }
    _buf.writeln('\n=== VALIDATOR REJECTED ===');
    _buf.writeln('rejected_count: ${rejectedCases.length}');
    for (final r in rejectedCases) {
      _buf.writeln('- ${r.title}');
      _buf.writeln('  Rejection reasons:');
      for (final reason in r.reasons) { _buf.writeln('    - $reason'); }
    }
    if (duplicateClusters.isNotEmpty) {
      _buf.writeln('\n=== DUPLICATE CLUSTERS ===');
      for (final cluster in duplicateClusters) {
        _buf.writeln('Cluster:');
        for (final title in cluster.titles) { _buf.writeln('- $title'); }
        _buf.writeln('Reason: ${cluster.reason}');
        _buf.writeln();
      }
    }
    _buf.writeln('\n=== AFTER DEDUP ===');
    _buf.writeln('remaining_count: ${afterDedup.length}');
    for (var i = 0; i < afterDedup.length; i++) { _buf.writeln('${i + 1}. ${afterDedup[i].title}'); }
    if (repairTransforms.isNotEmpty) {
      _buf.writeln('\n=== REPAIR TRANSFORMATIONS ===');
      for (final t in repairTransforms) {
        _buf.writeln('BEFORE: ${t.before}');
        _buf.writeln('AFTER: ${t.after}');
        _buf.writeln('TRANSFORMATIONS:');
        for (final a in t.actions) { _buf.writeln('- $a'); }
        _buf.writeln();
      }
    }
    _buf.writeln('\n=== AFTER REPAIR ===');
    _buf.writeln('repaired_count: ${afterRepair.length}');
    _buf.writeln('\n=== FINAL OUTPUT ===');
    _buf.writeln('final_count: ${finalCases.length}');
    for (final tc in finalCases) {
      _buf.writeln('- ${tc.title}');
      _buf.writeln('  Steps:');
      for (final step in tc.steps) {
        _buf.writeln('    - ${_safe(step.action, 100)} | data: ${_safe(step.data, 100)} | expected: ${_safe(step.expected, 100)}');
      }
      _buf.writeln('  Expected Result: ${_safe(tc.expectedResult, 200)}');
      _buf.writeln('  Priority: ${tc.priority}');
      _buf.writeln('  Type: ${tc.type}');
      _buf.writeln();
    }
    _buf.writeln('\n=== PIPELINE METRICS ===');
    _buf.writeln('generated: $aiGenerated');
    _buf.writeln('accepted: $accepted');
    _buf.writeln('repaired: $repaired');
    _buf.writeln('filtered: $filtered');
    _buf.writeln('duplicates_removed: $duplicatesRemoved');
    _buf.writeln('fallback_used: $fallbackUsed');
    _buf.writeln('generation_time_ms: $generationTimeMs');
    _buf.writeln('ai_failure: $aiFailure');
    _buf.writeln('prompt_tokens_estimate: $promptTokensEstimate');
    _buf.writeln('response_tokens_estimate: $responseTokensEstimate');
    _buf.writeln('\n$sep');
    _buf.writeln('END');
    _buf.writeln(sep);
  }
}
