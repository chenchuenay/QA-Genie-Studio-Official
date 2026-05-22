import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
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
  final String testCaseId;
  final String before;
  final String after;
  final String reason;
  final List<String> actions;
  RepairTransform(this.testCaseId, this.before, this.after, this.reason, this.actions);
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
  String operationId = "";

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

  void recordRepairTransform(
    String testCaseId,
    String before,
    String after,
    String reason,
    List<String> actions,
  ) {
    repairTransforms.add(RepairTransform(testCaseId, before, after, reason, actions));
  }

  void finalize() {
    _stopwatch.stop();
    generationTimeMs = _stopwatch.elapsedMilliseconds;
    promptTokensEstimate = (finalApiPrompt.length / 4).ceil();
    responseTokensEstimate = (rawAiResponse.length / 4).ceil();
  }

  Future<void> writeToDisk() async {
    finalize();
    final debugDir = Directory('cache/test_results');
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
    _buf.writeln('[QA GENIE END-TO-END FORENSIC REPLAY]');
    final sep = '=' * 72;
    _buf.writeln(sep);
    _buf.writeln('MODE: ${_mode == PipelineMode.core ? 'CORE' : 'PRO'}');
    _buf.writeln('session_id: $sessionId');
    _buf.writeln('generated_at: $createdAt');
    _buf.writeln(sep);
    _buf.writeln('\n=== INPUT ===');
    _buf.writeln('module: $module');
    _buf.writeln('feature: $feature');
    _buf.writeln('platform: $platform');
    _buf.writeln('constraints: $constraints');
    _buf.writeln('requested_count: $requestedCount');
    _buf.writeln('\n=== FINAL API PROMPT ===');
    _buf.writeln(_cap(finalApiPrompt, 30000));
    _buf.writeln('\n=== RAW AI RESPONSE ===');
    _buf.writeln(_cap(rawAiResponse, 50000));
    _buf.writeln('\n=== PARSED TEST CASES ===');
    _buf.writeln('generated_count: ${parsedCases.length}');
    for (var i = 0; i < parsedCases.length; i++) {
      final tc = parsedCases[i];
      _buf.writeln('${i + 1}. ${tc.title}');
    }
    _buf.writeln('\n=== VALIDATOR REJECTED ===');
    _buf.writeln('rejected_count: ${rejectedCases.length}');
    for (final r in rejectedCases) {
      _buf.writeln('- ${r.title}');
    }
    _buf.writeln('\n=== FINAL OUTPUT ===');
    _buf.writeln('final_count: ${finalCases.length}');
    for (final tc in finalCases) {
      _buf.writeln('- title: ${tc.title}');
      _buf.writeln('  priority: ${tc.priority}');
      _buf.writeln('  type: ${tc.type}');
      _buf.writeln('  preconditions: ${tc.preconditions}');
      _buf.writeln('  steps:');
      for (final step in tc.steps) {
        _buf.writeln('    - action: ${step.action}');
        _buf.writeln('      data: ${step.data}');
        _buf.writeln('      expected: ${step.expected}');
      }
      _buf.writeln('  expectedResult: ${tc.expectedResult}');
      _buf.writeln('  status: ${tc.status}');
      _buf.writeln();
    }
    _buf.writeln('\n=== PIPELINE METRICS ===');
    _buf.writeln('ai_cases=$aiGenerated');
    _buf.writeln('accepted=$accepted');
    _buf.writeln('repaired=$repaired');
    _buf.writeln('fallback_cases=${fallbackUsed ? finalCases.length : 0}');
    _buf.writeln('filtered=$filtered');
    _buf.writeln('duration_ms=$generationTimeMs');
    _buf.writeln('session_completed=true');
    _buf.writeln('session_integrity_hash=${sha256.convert(utf8.encode(_buf.toString())).toString()}');
    _buf.writeln('\n$sep');
    _buf.writeln('END');
    _buf.writeln(sep);
  }
}

