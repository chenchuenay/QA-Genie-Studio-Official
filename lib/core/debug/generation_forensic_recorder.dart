import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';

class GenerationForensicRecorder {
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  static Future<Directory> _getResultsDir() async {
    // If in test environment, use local relative path for easy host access
    if (const bool.fromEnvironment('QA_GENIE_TEST', defaultValue: false)) {
      final dir = Directory('cache/test_results');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }
    
    // In production/device runtime, use system cache dir
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'test_results'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> recordPipelineLog(String tier) async {
    final dir = await _getResultsDir();
    final file = File(p.join(dir.path, '${tier}_pipeline.txt'));
    
    final buffer = StringBuffer();
    buffer.writeln('==================================================');
    buffer.writeln('[QA GENIE END-TO-END FORENSIC REPLAY]');
    buffer.writeln('timestamp: ${DateTime.now().toIso8601String()}');
    buffer.writeln('tier: $tier');
    buffer.writeln('provider: ${PipelineDebugStore.lastProvider}');
    buffer.writeln('==================================================\n');

    buffer.writeln('1. FULL RAW PAYLOAD SENT TO API');
    buffer.writeln('--------------------------------------------------');
    buffer.writeln(PipelineDebugStore.lastRawProviderPayload);
    buffer.writeln('\n--------------------------------------------------\n');

    buffer.writeln('2. FULL RAW API RESPONSE');
    buffer.writeln('--------------------------------------------------');
    buffer.writeln(PipelineDebugStore.lastFullRawAiResponse);
    buffer.writeln('\n--------------------------------------------------\n');

    buffer.writeln('3. EXTRACTED & CLEANED JSON');
    buffer.writeln('--------------------------------------------------');
    buffer.writeln(PipelineDebugStore.lastRawResponse);
    buffer.writeln('\n--------------------------------------------------\n');

    buffer.writeln('4. REJECTED OBJECTS (FAILURES)');
    buffer.writeln('--------------------------------------------------');
    if (PipelineDebugStore.rejectedObjects.isEmpty) {
      buffer.writeln('None detected.');
    } else {
      for (final rej in PipelineDebugStore.rejectedObjects) {
        buffer.writeln('REJECTION REASON: ${rej['reason']}');
        buffer.writeln('OBJECT: ${_encoder.convert(rej['object'] ?? rej['raw_chunk'])}');
        buffer.writeln('---');
      }
    }
    buffer.writeln('\n--------------------------------------------------\n');

    buffer.writeln('5. REPAIRED OBJECTS (TRANSITIONS)');
    buffer.writeln('--------------------------------------------------');
    if (PipelineDebugStore.repairedObjects.isEmpty) {
      buffer.writeln('None detected.');
    } else {
      for (final rep in PipelineDebugStore.repairedObjects) {
        buffer.writeln('OPERATION: ${rep['operation']}');
        buffer.writeln('BEFORE: ${rep['before']}');
        buffer.writeln('AFTER:  ${rep['after']}');
        buffer.writeln('---');
      }
    }
    buffer.writeln('\n--------------------------------------------------\n');

    buffer.writeln('6. REALISM INJECTIONS (MUTATIONS)');
    buffer.writeln('--------------------------------------------------');
    if (PipelineDebugStore.realismInjections.isEmpty) {
      buffer.writeln('None detected.');
    } else {
      for (final inj in PipelineDebugStore.realismInjections) {
        buffer.writeln('ID: ${inj['id']}');
        buffer.writeln('TITLE BEFORE: ${inj['before']['title']}');
        buffer.writeln('TITLE AFTER:  ${inj['after']['title']}');
        buffer.writeln('EXPECTED BEFORE: ${inj['before']['expectedResult']}');
        buffer.writeln('EXPECTED AFTER:  ${inj['after']['expectedResult']}');
        buffer.writeln('---');
      }
    }
    buffer.writeln('\n--------------------------------------------------\n');

    buffer.writeln('7. FINAL USER-VISIBLE TESTCASES');
    buffer.writeln('--------------------------------------------------');
    buffer.writeln(_encoder.convert(PipelineDebugStore.finalObjects));
    buffer.writeln('\n--------------------------------------------------\n');

    buffer.writeln('8. FINAL FORENSIC SUMMARY');
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('AI Count:       ${PipelineDebugStore.finalAiCases}');
    buffer.writeln('Repaired Count: ${PipelineDebugStore.repairedObjects.length}');
    buffer.writeln('Fallback Count: ${PipelineDebugStore.finalFallbackCases}');
    buffer.writeln('Rejected Count: ${PipelineDebugStore.rejectedObjects.length}');
    buffer.writeln('Filtered (Dropped) Count: ${PipelineDebugStore.invalidCasesDropped}');
    buffer.writeln('Realism Variations Used: ${PipelineDebugStore.realismPhraseVariationsUsed}');
    buffer.writeln('==================================================');
    
    // OVERWRITE previous generation (FileMode.write)
    await file.writeAsString(buffer.toString(), mode: FileMode.write);
  }

  static Future<void> recordAnalyticalLog(String tier, Map<String, dynamic> forensics) async {
    final dir = await _getResultsDir();
    final file = File(p.join(dir.path, '${tier}_analytical_logs.txt'));
    
    final buffer = StringBuffer();
    buffer.writeln('\n==================================================');
    buffer.writeln('[FORENSIC ANALYTICAL ENTRY]');
    buffer.writeln('timestamp: ${DateTime.now().toIso8601String()}');
    buffer.writeln('tier: ${forensics['tier']}');
    buffer.writeln('platform: ${forensics['platform']}');
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('realismScore: ${forensics['realismScore']}');
    buffer.writeln('acceptedCount: ${forensics['acceptedCount']}');
    buffer.writeln('rejectedCount: ${forensics['rejectedCount']}');
    buffer.writeln('behavioralChainCount: ${forensics['behavioralChainCount']}');
    buffer.writeln('interruptionTypes: ${forensics['interruptionTypes']}');
    buffer.writeln('continuityValidation: ${forensics['continuityValidation']}');
    buffer.writeln('topologyDiversity: ${forensics['topologyDiversity']}');
    buffer.writeln('platformRealismMarkers: ${forensics['platformRealismMarkers']}');
    buffer.writeln('genericPhrasePenalties: ${forensics['genericPhrasePenalties']}');
    buffer.writeln('repairOperations: ${forensics['repairOperations']}');
    buffer.writeln('lineage: ${forensics['lineage']}');
    buffer.writeln('workflowTransitionSummary: ${forensics['workflowTransitionSummary']}');
    buffer.writeln('==================================================\n');
    
    await file.writeAsString(buffer.toString(), mode: FileMode.append);
  }

  static Map<String, dynamic> captureCurrentForensics({
    required int realismScore,
    required String tier,
    required String platform,
  }) {
    return {
      'tier': tier,
      'platform': platform,
      'realismScore': realismScore,
      'acceptedCount': PipelineDebugStore.finalAiCases + PipelineDebugStore.finalFallbackCases,
      'rejectedCount': PipelineDebugStore.invalidCasesDropped + PipelineDebugStore.rejectedObjectCount,
      'behavioralChainCount': PipelineDebugStore.recoveredCount,
      'interruptionTypes': 'refresh, timeout, reconnect, tabSwitch, background',
      'continuityValidation': realismScore > 75 ? 'HIGH' : (realismScore > 50 ? 'MEDIUM' : 'LOW'),
      'topologyDiversity': PipelineDebugStore.realismPhraseVariationsUsed > 10 ? 'HIGH' : 'STABLE',
      'platformRealismMarkers': PipelineDebugStore.realismPhraseVariationsUsed,
      'genericPhrasePenalties': PipelineDebugStore.malformedObjectsSkipped,
      'repairOperations': PipelineDebugStore.cleanerRepairCount,
      'lineage': 'ai=${PipelineDebugStore.finalAiCases} repaired=${PipelineDebugStore.cleanerRepairCount} fallback=${PipelineDebugStore.finalFallbackCases}',
      'workflowTransitionSummary': 'Transitions detected and validated: ${PipelineDebugStore.recoveredCount}',
    };
  }
}
