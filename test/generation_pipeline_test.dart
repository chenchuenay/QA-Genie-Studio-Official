import 'dart:io';
import 'support/live_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qa_genie/engine/generation_service.dart';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';





void main() {
  ensureLiveGroqNetworking();

  test(
    'DEEP FORENSIC GENERATION (REAL PIPELINE)',
    () async {
      // ============================================================
      // ENV LOAD
      // ============================================================

      final envFile = File('.env');

      if (envFile.existsSync()) {
        dotenv.testLoad(fileInput: envFile.readAsStringSync());
      }

      // ============================================================
      // PIPELINE MODE
      // ============================================================

      const mode = String.fromEnvironment(
        'PIPELINE_MODE',
        defaultValue: 'core',
      );

      final normalizedMode = mode.trim().toLowerCase();

      final isPro = normalizedMode == 'pro';

      final expectedCount = isPro ? 16 : 8;

      print('''
==================================================
PIPELINE MODE
==================================================

${isPro ? 'PRO' : 'CORE'}

Expected Count:
$expectedCount
''');

      // ============================================================
      // REAL SERVICE
      // ============================================================

      final service = GenerationService();

      // ============================================================
      // REAL EXECUTION
      // ============================================================

      const module = 'Authentication';

      const feature = 'user login with email';

      const platform = 'Web';

      final result = await service.execute(
        module: module,
        feature: feature,
        platform: platform,

        // CURRENT REAL ARCHITECTURE
        // count-driven tiering
        maxCases: expectedCount,
      );

      // ============================================================
      // RAW RESPONSE
      // ============================================================

      print('\n--- RAW AI RESPONSE ---\n');

      print(PipelineDebugStore.lastRawResponse);

      // ============================================================
      // FORENSIC ANALYSIS
      // ============================================================

      print('\n--- FORENSIC ANALYSIS ---\n');

      print(
        'Provider: '
        '${PipelineDebugStore.lastProvider}',
      );

      print(
        'Final Output Count: '
        '${result.cases.length}',
      );

      // ============================================================
      // UNIQUE TYPES
      // ============================================================

      final uniqueTypes = result.cases.map((c) => c.type).toSet();

      print(
        'Unique types generated: '
        '$uniqueTypes',
      );

      // ============================================================
      // STEP QUALITY
      // ============================================================

      final avgSteps =
          result.cases.map((tc) => tc.steps.length).reduce((a, b) => a + b) /
          result.cases.length;

      print(
        'Average steps per case: '
        '${avgSteps.toStringAsFixed(2)}',
      );

      final meaningfulSteps = result.cases.map((tc) {
        return tc.steps.where((s) {
          return s.action.length > 10 && s.expected.length > 20;
        }).length;
      }).toList();

      print(
        'Meaningful steps distribution: '
        '$meaningfulSteps',
      );

      // ============================================================
      // FILLER DETECTION
      // ============================================================

      final fillerPhrases = [
        'perform action',
        'check result',
        'verify system',
        'observe page',
        'inspect',
      ];

      int fillerCount = 0;

      for (final tc in result.cases) {
        for (final step in tc.steps) {
          final lower = step.action.toLowerCase();

          if (fillerPhrases.any(lower.contains)) {
            fillerCount++;
          }
        }
      }

      print(
        'Total filler phrases detected: '
        '$fillerCount',
      );

      // ============================================================
      // STREAM RECOVERY
      // ============================================================

      print('''
==================================================
STREAM RECOVERY
==================================================

Recovered:
${PipelineDebugStore.recoveredObjects}

Dropped:
${PipelineDebugStore.droppedObjects}
''');

      // ============================================================
      // SOFT FORENSIC WARNINGS
      // OBSERVABILITY ONLY
      // ============================================================

      if (fillerCount > 0) {
        print(
          '[FORENSIC WARNING] '
          'Generic filler wording detected.',
        );
      }

      if (uniqueTypes.length < 4) {
        print(
          '[FORENSIC WARNING] '
          'Low type diversity detected.',
        );
      }

      // ============================================================
      // HARD ASSERTIONS
      // ============================================================

      expect(result.cases, isNotEmpty);

      expect(result.cases.length, equals(expectedCount));

      expect(PipelineDebugStore.estimatedInputTokens, lessThan(4000));

      expect(fillerCount, equals(0));

      // ============================================================
      // PRUNING VALIDATION
      // ============================================================

      for (final tc in result.cases) {
        expect(tc.module, isEmpty, reason: 'Module should be pruned');

        expect(tc.feature, isEmpty, reason: 'Feature should be pruned');

        expect(tc.platform, isEmpty, reason: 'Platform should be pruned');

        expect(
          tc.actualResult,
          isEmpty,
          reason: 'ActualResult should be pruned',
        );

        expect(tc.status, isEmpty, reason: 'Status should be pruned');
      }

      // ============================================================
      // FORENSIC FILE VALIDATION
      // ============================================================

      final forensicFile = File(
        isPro
            ? 'cache/test_results/pro_pipeline.txt'
            : 'cache/test_results/core_pipeline.txt',
      );

      expect(forensicFile.existsSync(), isTrue);

      final contentA = forensicFile.readAsStringSync();

      expect(contentA.contains('user login with email'), isTrue);

      // ============================================================
      // REQUIRED SECTIONS
      // ============================================================

      final requiredSections = [
        '[QA GENIE END-TO-END FORENSIC REPLAY]',
        '=== INPUT ===',
        '=== FINAL API PROMPT ===',
        '=== RAW AI RESPONSE ===',
        '=== PARSED TEST CASES ===',
        '=== VALIDATOR REJECTED ===',
        '=== FINAL OUTPUT ===',
        '=== PIPELINE METRICS ===',
      ];

      for (final section in requiredSections) {
        expect(
          contentA.contains(section),
          isTrue,
          reason:
              'Missing forensic section: '
              '$section',
        );
      }

      // ============================================================
      // OVERWRITE ISOLATION TEST
      // ============================================================

      await service.execute(
        module: 'IsolationTest',
        feature: 'OVERWRITE_MARKER_B',
        platform: 'Web',

        // REAL CURRENT ARCHITECTURE
        maxCases: expectedCount,
      );

      final contentB = forensicFile.readAsStringSync();

      expect(contentB.contains('OVERWRITE_MARKER_B'), isTrue);

      expect(
        contentB.contains('user login with email'),
        isFalse,
        reason:
            'Marker A still exists. '
            'Overwrite isolation failed.',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
