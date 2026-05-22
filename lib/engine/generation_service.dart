import 'package:qa_genie/core/validators/structural_case_validator.dart';
import 'package:qa_genie/engine/models/generation_complexity_profile.dart';
import 'package:qa_genie/core/utils/token_budget_calculator.dart';
import 'package:qa_genie/core/debug/generation_forensic_recorder.dart';
import 'package:qa_genie/engine/humanization/qa_realism_enforcer.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'dart:math';
import 'package:qa_genie/engine/platform_rules.dart';
import 'package:qa_genie/engine/generation_mode.dart';
import 'package:qa_genie/core/utils/stable_hash.dart';
import 'package:qa_genie/core/utils/id_generator.dart';
import 'package:qa_genie/engine/scenario_planner.dart';
import 'package:qa_genie/core/logging/dump_writer.dart';
import 'package:qa_genie/engine/generation_result.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/core/utils/priority_utils.dart';
import 'package:qa_genie/engine/generation_metrics.dart';
import 'package:qa_genie/core/error/ui_error_store.dart';
import 'package:qa_genie/core/debug/pipeline_logger.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/engine/deterministic_repair.dart';
import 'package:qa_genie/engine/qa_heuristics_engine.dart';
import 'package:qa_genie/core/error/ui_error_service.dart';
import 'package:qa_genie/core/logging/logging_config.dart';
import 'package:qa_genie/core/utils/test_data_factory.dart';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';
import 'package:qa_genie/core/logging/analytical_formatter.dart';
import 'package:qa_genie/engine/fallback/fallback_generator.dart';
import 'package:qa_genie/core/prompts/system_prompt.dart';
import 'package:qa_genie/core/network/response_parser.dart';
import 'package:qa_genie/core/network/providers/provider_factory.dart';

/// Exported-case lineage tally (canonical [CaseSource] only).
({int ai, int detRepair, int fallback}) _finalSuiteOriginTally(
  List<TestCaseModel> suite,
) {
  var ai = 0;
  var repaired = 0;
  var fallback = 0;

  for (final tc in suite) {
    switch (tc.source) {
      case CaseSource.ai:
        ai++;
        break;

      case CaseSource.repairedAi:
        repaired++;
        break;

      case CaseSource.fallback:
        fallback++;
        break;
    }
  }

  return (ai: ai, detRepair: repaired, fallback: fallback);
}

/// Mutable counters shared across pipeline stages. Kept as one struct so
/// orchestration does not scatter metric updates.
class _PipelineCounters {
  int aiGenerated = 0;
  int aiAccepted = 0;
  int filteredCount = 0;
  int duplicatesRemovedCount = 0;

  /// Cases removed ONLY in `_deduplicateAfterRepairStage` (semantic + hash collapse).
  int postRepairDuplicatesRemoved = 0;
  int repairedCount = 0;
  int aiCalls = 0;
  String? aiFailureReason;
  bool fallbackUsed = false;
}

class GenerationService {
  static const bool bypassPipeline = false;

  bool _isGenerating = false;
  static GenerationMetrics _lastMetrics = const GenerationMetrics();

  static GenerationMetrics get lastMetrics => _lastMetrics;

  String? _lastWarning;
  String? get lastWarning => _lastWarning;

  static const String PROMPT_VERSION = "v1.4";

  static const List<String> _bannedPhrases = [
    // Generic filler outcomes
    "works correctly",
    "works as expected",
    "behaves as expected",
    "successful operation",
    "operation successful",
    "everything works fine",
    "expected result achieved",
    "user can proceed successfully",
    "operation completed successfully",
    "action completes without errors",
    "stable behavior",
    "default workflow stability",
    "workflow stability",

    // Generic template spam
    "scenario 1",
    "prepare for scenario",
    "execute scenario",
    "verify outcome",
    "context-specific input",
    "application responds correctly",
    "system processes the request correctly",
    "workflow loads successfully",
    "system handles the interaction correctly",
    "valid_input",

    // Placeholder / fake data
    "user@example.com",
    "test@example.com",
    "example@test.com",
    "password123",
    "admin123",
    "placeholder",
    "dummy data",
    "sample password",
    "sample data",
    "lorem ipsum",

    // Wrong or unsafe generation artifacts
    ".repeat(",
    "replace(\"",

    // Generic meaningless actions
    "click button",
    "enter details",
    "submit form",
    "check result",
    "verify success",

    // Weak fake test data labels
    "test data",
    "correct values",
  ];

  bool _containsGarbage(TestCaseModel tc) {
    final combined =
        (tc.title +
                ' ' +
                tc.expectedResult +
                ' ' +
                tc.steps
                    .map((s) => '${s.action} ${s.data} ${s.expected}')
                    .join(' ') +
                ' ' +
                tc.preconditions.join(' '))
            .toLowerCase();
    return _bannedPhrases.any((phrase) => combined.contains(phrase));
  }

  bool _violatesPlatform(TestCaseModel tc, String platform) {
    final combined =
        '${tc.title} ${tc.expectedResult} ${tc.preconditions.join(' ')} '
        '${tc.steps.map((s) => '${s.action} ${s.data} ${s.expected}').join(' ')}';
    return PlatformRules.violatesPlatform(platform, combined);
  }

  String _intentSignature(TestCaseModel tc) {
    final normalizedTitle = tc.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();

    final firstAction = tc.steps.isNotEmpty
        ? tc.steps.first.action
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
              .trim()
        : '';

    final expected = tc.expectedResult
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();

    return '$normalizedTitle|$firstAction|$expected';
  }

  int _qualityScore(TestCaseModel tc) {
    int score = 0;
    if (tc.title.trim().isNotEmpty && !tc.title.contains(RegExp(r'^\d+$')))
      score += 1;
    // Score based on meaningful content
    final meaningfulCount = tc.steps
        .where(QaHeuristicsEngine.isMeaningfulStep)
        .length;
    if (meaningfulCount >= 3) score += 1;
    if (tc.steps.any(
      (s) =>
          s.data.contains('@') &&
          !_bannedPhrases.any((p) => s.data.toLowerCase().contains(p)),
    ))
      score += 2;
    if (tc.steps.any(
      (s) =>
          s.data.length > 5 &&
          !_bannedPhrases.any((p) => s.data.toLowerCase().contains(p)),
    ))
      score += 2;
    if (tc.expectedResult.length > 40 &&
        !_bannedPhrases.any((p) => tc.expectedResult.toLowerCase().contains(p)))
      score += 2;
    if (!QaHeuristicsEngine.hasWeakExpectedResult(tc.expectedResult)) {
      score += 3;
    }
    final verbs = tc.steps
        .map((s) => s.action.split(' ').first.toLowerCase())
        .toSet();
    if (verbs.length >= 3) score += 2;

    // contextual variation bonus
    if (tc.steps.any((s) => s.action.contains(tc.feature))) score += 1;

    return score;
  }

  Future<GenerationResult> execute({
    required String module,
    required String feature,
    required String platform,
    required int maxCases,
    String? notes,
    int startIndex = 1,
    String domain = 'general',
  }) async {
    if (_isGenerating) return const GenerationResult(cases: []);
    _isGenerating = true;

    // Generate operation ID for this batch
    final operationId =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
    UiErrorStore().startOperation(operationId);
    UiErrorStore().clear();

    try {
      final List<TestCaseModel> generatedCases = await _performGeneration(
        module: module,
        feature: feature,
        platform: platform,
        maxCases: maxCases,
        notes: notes,
        startIndex: startIndex,
        domain: domain,
        operationId: operationId,
      );
      return GenerationResult(cases: generatedCases, warning: _lastWarning);
    } finally {
      _isGenerating = false;
    }
  }

  Future<List<TestCaseModel>> _performGeneration({
    required String module,
    required String feature,
    required String platform,
    required int maxCases,
    String? notes,
    required int startIndex,
    String domain = 'general',
    required String operationId,
  }) async {
    final totalStopwatch = Stopwatch()..start();

    final promptStopwatch = Stopwatch();

    final apiStopwatch = Stopwatch();

    final parseStopwatch = Stopwatch();

    final validationStopwatch = Stopwatch();

    final repairStopwatch = Stopwatch();

    final fallbackStopwatch = Stopwatch();
    final mode = parseConstraints(notes);
    final inferredDomain = QaHeuristicsEngine.inferDomain(
      module,
      feature,
      domain,
    );
    final targetCount = maxCases > 8 ? 16 : 8;
    final isProMode = targetCount == 16;
    final planner = ScenarioPlanner(
      module: module,
      feature: feature,
      platform: platform,
      mode: mode,
      count: targetCount,
      domain: inferredDomain,
    );
    final skeletons = planner.generateSkeletons();

    final c = _PipelineCounters();
    final pipelineLog = PipelineLogger(
      isProMode ? PipelineMode.pro : PipelineMode.core,
    );
    pipelineLog.operationId = operationId;
    pipelineLog.module = module;
    pipelineLog.feature = feature;
    pipelineLog.platform = platform;
    pipelineLog.constraints = notes ?? '';
    pipelineLog.requestedCount = targetCount;
    PipelineDebugStore.resetAll();
    
    promptStopwatch.start();
    final prompt = _buildPromptStage(
      skeletons: skeletons,
      module: module,
      feature: feature,
      platform: platform,
    );
    pipelineLog.basePrompt = prompt;
    pipelineLog.finalApiPrompt = prompt;
    promptStopwatch.stop();

    PipelineDebugStore.lastFinalPrompt = prompt;

    // --- Single provider call: parse + transport errors fold into catch path. ---
    apiStopwatch.start();

    List<TestCaseModel> cases = await _aiGenerationStage(
      prompt: prompt,
      module: module,
      feature: feature,
      platform: platform,
      maxCases: targetCount,
      pipelineLog: pipelineLog,
      c: c,
      apiStopwatch: apiStopwatch,
    );

    // Local recovery from raw / noisy model output (no second API call).
    // COUNT RISK: garbage filter can shrink the list; empty list is allowed.
    parseStopwatch.start();
    cases = _responseRecoveryStage(
      cases: cases,
      module: module,
      feature: feature,
      platform: platform,
      inferredDomain: inferredDomain,
      c: c,
      apiStopwatch: apiStopwatch,
    );

    cases = _semanticRecoveryStage(
      cases: cases,
      module: module,
      feature: feature,
      platform: platform,
      inferredDomain: inferredDomain,
      pipelineLog: pipelineLog,
      c: c,
    );

    // Baseline BEFORE quality rejection (historic `filteredCount` semantics).
    parseStopwatch.stop();

    final beforeFilter = cases.length;

    // COUNT RISK: quality + platform filters can shrink; empty triggers full fallback.
    // FALLBACK: deterministic suite replaces AI output when nothing passes quality.
    validationStopwatch.start();
    cases = _qualityValidationStage(
      cases: cases,
      platform: platform,
      targetCount: targetCount,
      module: module,
      feature: feature,
      inferredDomain: inferredDomain,
      pipelineLog: pipelineLog,
      c: c,
    );
    validationStopwatch.stop();

    if (cases.length > targetCount) {
      cases = cases.take(targetCount).toList();
    }

    final platformFiltered = cases
        .where((tc) => !_violatesPlatform(tc, platform))
        .toList();
    // Prefer an empty staged list after platform violation → downstream gap fill/recovery.
    cases = platformFiltered;
    // COUNT RISK vs pre-quality baseline (historical semantics).
    c.filteredCount = beforeFilter > cases.length
        ? beforeFilter - cases.length
        : 0;
    c.aiAccepted = cases.length;
    
    final hardLimit = isProMode ? 16 : 8;
    if (cases.length > hardLimit) {
      cases = cases.take(hardLimit).toList();
    }
    
    pipelineLog.acceptedCases = List.from(cases);

    if (bypassPipeline) {
      return await _finalInvariantStage(
        cases: cases,
        targetCount: targetCount,
        module: module,
        feature: feature,
        platform: platform,
        inferredDomain: inferredDomain,
        bypassPipeline: true,
        startIndex: startIndex,
        pipelineLog: pipelineLog,
        counters: null,
      );
    }

    // DUPLICATE RISK: title + intent keys; PRO mode only logs diversity gaps.
    final dedupResult = _deduplicationStage(
      cases: cases,
      isProMode: isProMode,
      module: module,
      feature: feature,
      platform: platform,
      inferredDomain: inferredDomain,
      pipelineLog: pipelineLog,
      c: c,
    );
    cases = dedupResult.cases;

    // COUNT RISK: repair output length vs maxCases; post-repair rejection filter shrinks.
    repairStopwatch.start();
    cases = _deterministicRepairStage(
      cases: cases,
      maxCases: maxCases,
      planner: planner,
      module: module,
      feature: feature,
      platform: platform,
      inferredDomain: inferredDomain,
      pipelineLog: pipelineLog,
      c: c,
    );

    if (cases.length > targetCount) {
      cases = cases.take(targetCount).toList();
    }
    
    // DUPLICATE RISK: second intent pass + structural hash uniq (may noop if empty).
    repairStopwatch.stop();

    cases = _deduplicateAfterRepairStage(
      cases: cases,
      module: module,
      feature: feature,
      platform: platform,
      inferredDomain: inferredDomain,
      pipelineLog: pipelineLog,
      c: c,
    );

    if (cases.length > targetCount) {
      cases = cases.take(targetCount).toList();
    }
    
    // COUNT RISK / FALLBACK: gap fill expands toward target via fallback + emergency.
    // Only invocation of `_fillCanonicalGaps` remains here (aside from internal calls).
    fallbackStopwatch.start();
    final beforeGapFill = cases.length;
    cases = _fallbackFillStage(
      cases: cases,
      targetCount: targetCount,
      module: module,
      feature: feature,
      platform: platform,
      inferredDomain: inferredDomain,
      c: c,
    );
    if (cases.length > targetCount) {
      cases = cases.take(targetCount).toList();
    }
    
    if (cases.length > beforeGapFill) {
      c.fallbackUsed = true;
      c.repairedCount += cases.length - beforeGapFill;
    }
    fallbackStopwatch.stop();

    final finalized = await _finalInvariantStage(
      cases: cases,
      targetCount: targetCount,
      module: module,
      feature: feature,
      platform: platform,
      inferredDomain: inferredDomain,
      bypassPipeline: false,
      startIndex: startIndex,
      pipelineLog: pipelineLog,
      counters: c,
    );

    final finalLimit = isProMode ? 16 : 8;
    final casesToReturn = finalized.take(finalLimit).toList();

    final lineage = _finalSuiteOriginTally(casesToReturn);

    final metrics = GenerationMetrics(
      aiGenerated: c.aiGenerated,
      aiAccepted: c.aiAccepted,
      repairedCount: c.repairedCount,
      filteredCount: c.filteredCount,
      aiCalls: c.aiCalls,
      aiFailure: c.aiFailureReason != null,
      aiFailureReason: c.aiFailureReason,
      finalAiOriginCount: lineage.ai,
      finalDeterministicOriginCount: lineage.detRepair,
      fallbackInjectedCount: lineage.fallback,
    );
    
    _lastMetrics = metrics;
    if (c.aiFailureReason != null) {
      _lastWarning =
          'AI generation failed during parsing, validation, or network call.';
    } else if (metrics.deterministicShare >= 0.7) {
      _lastWarning =
          'Most cases were deterministically repaired after quality filtering.';
    } else {
      _lastWarning = null;
    }
    totalStopwatch.stop();

    print('[QA Genie Metrics] $metrics');
    if (LoggingConfig.forensicLogging) {
      try {
        final analyticalDump = AnalyticalFormatter.buildAnalyticalDump(casesToReturn);
        if (isProMode) {
          await DumpWriter.appendProAnalytical(analyticalDump);
        } else {
          await DumpWriter.appendCoreAnalytical(analyticalDump);
        }
      } catch (_) {}
    }
    assert(
      casesToReturn.length <= (isProMode ? 16 : 8),
      'FINAL CASE LIMIT VIOLATION: ${casesToReturn.length}',
    );
    return casesToReturn;
  }

  /// Builds the single API payload for this generation (no network I/O).
  String _buildPromptStage({
    required List<Map<String, dynamic>> skeletons,
    required String module,
    required String feature,
    required String platform,
  }) {
    return _buildEnrichmentPrompt(skeletons, module, feature, platform);
  }

  /// Exactly one `_api.generate` call. On failure uses `FallbackGenerator` with
  /// `maxCases` (historical behavior; not `targetCount`).
  Future<List<TestCaseModel>> _aiGenerationStage({
    required String prompt,
    required String module,
    required String feature,
    required String platform,
    required int maxCases,
    required PipelineLogger pipelineLog,
    required _PipelineCounters c,
    required Stopwatch apiStopwatch,
  }) async {
    try {
      if (c.aiCalls > 0) {
        throw Exception(
          'Only one AI provider call is allowed per generation. No retries or regenerations.',
        );
      }

      c.aiCalls++;

      final isPro = await UsageManager.isPro();
      
      final profile = GenerationComplexityProfile(
        module: module,
        feature: feature,
        platform: platform,
        requestedCases: maxCases,
        isPro: isPro,
        intents: [],
      );

      final maxTokens = TokenBudgetCalculator.calculate(profile);

      // Using local provider directly instead of wrapped API
      final provider = ProviderFactory.create();
      final rawResponse = await provider.generate(prompt, maxTokens: maxTokens);
      apiStopwatch.stop();

      final cases = ResponseParser.parseArray(rawResponse);

      if (cases.isEmpty) {
        throw Exception('AI returned zero test cases');
      }

      pipelineLog.parsedCases = List.from(cases);
      pipelineLog.aiGenerated = cases.length;
      c.aiGenerated = cases.length;

      return cases;
    } catch (e, stack) {
      final aiFailureReason = e.toString();

      c.aiFailureReason = aiFailureReason;
      pipelineLog.recordParseFailure(aiFailureReason);

      // Log the AI failure as a UI error
      UiErrorService.logOnly(
        source: ErrorSource.aiProvider,
        screen: 'GenerationService',
        stage: ErrorStage.aiCall,
        severity: ErrorSeverity.error,
        userMessage: 'AI generation failed: $aiFailureReason',
        error: e,
        stack: stack,
      );

      // HARD FALLBACK RECOVERY (still no additional AI call).
      final cases = FallbackGenerator.generate(
        count: maxCases,
        module: module,
        feature: feature,
        platform: platform,
      );

      c.fallbackUsed = true;
      c.aiGenerated = 0;
      c.aiAccepted = cases.length;
      return cases;
    }
  }

  List<TestCaseModel> _responseRecoveryStage({
    required List<TestCaseModel> cases,
    required String module,
    required String feature,
    required String platform,
    required String inferredDomain,
    required _PipelineCounters c,
    required Stopwatch apiStopwatch,
  }) {
    // COUNT SHRINK: only discard unrecoverable transport/template artifacts here.
    // Semantically weak wording is repaired in-place by `_semanticRecoveryStage`.
    final filteredGarbage = cases
        .where((tc) => !_containsUnrecoverableGarbage(tc))
        .toList();
    var next = filteredGarbage.isNotEmpty
        ? filteredGarbage
        : List<TestCaseModel>.from(cases);

    if (next.isEmpty) {
      c.aiFailureReason ??= 'AI produced no usable test cases after filtering.';
    }

    for (final tc in next) {
      if (tc.expectedResult.trim().isEmpty) {
        tc.expectedResult = _expertExpectedResult(
          tc,
          module,
          feature,
          platform,
          inferredDomain,
        );
      } else if (QaHeuristicsEngine.hasWeakExpectedResult(tc.expectedResult)) {
        tc.expectedResult = _expertExpectedResult(
          tc,
          module,
          feature,
          platform,
          inferredDomain,
        );
      }
    }

    final featureLower = feature.toLowerCase();
    final moduleLower = module.toLowerCase();
    next = next.where((tc) {
      final combined =
          (tc.title + ' ' + tc.steps.map((s) => s.action).join(' '))
              .toLowerCase();
      if (moduleLower.contains('login') || featureLower.contains('login')) {
        if (combined.contains('checkout') ||
            combined.contains('payment') ||
            combined.contains('card') ||
            combined.contains('order'))
          return false;
      }
      if (moduleLower.contains('payment') || featureLower.contains('payment')) {
        if (combined.contains('login') || combined.contains('signup'))
          return false;
      }
      return true;
    }).toList();

    // In-place enrichment on surviving cases.
    for (final tc in next) {
      tc.priority = _riskPriority(
        tc,
        module,
        feature,
        platform,
        inferredDomain,
      );
    }

    for (final tc in next) {
      _normalizeCanonicalCase(
        tc,
        module: module,
        feature: feature,
        platform: platform,
        domain: inferredDomain,
      );
    }

    return next;
  }

  bool _containsUnrecoverableGarbage(TestCaseModel tc) {
    final combined =
        (tc.title +
                ' ' +
                tc.expectedResult +
                ' ' +
                tc.steps
                    .map((s) => '${s.action} ${s.data} ${s.expected}')
                    .join(' ') +
                ' ' +
                tc.preconditions.join(' '))
            .toLowerCase();

    const hardGarbage = [
      '.repeat(',
      'replace("',
      'lorem ipsum',
      'placeholder',
      'dummy data',
      'password123',
      'admin123',
      'valid_input',
    ];

    return hardGarbage.any(combined.contains);
  }

  List<TestCaseModel> _semanticRecoveryStage({
    required List<TestCaseModel> cases,
    required String module,
    required String feature,
    required String platform,
    required String inferredDomain,
    required PipelineLogger pipelineLog,
    required _PipelineCounters c,
  }) {
    final recovered = <TestCaseModel>[];

    for (var i = 0; i < cases.length; i++) {
      final tc = cases[i];
      final beforeScore = QaHeuristicsEngine.semanticScore(tc);
      final beforeRejection = _canonicalRejectionReason(tc, platform);
      final before = _semanticSnapshot(tc);

      final actions = _repairSemanticCase(
        tc,
        module: module,
        feature: feature,
        platform: platform,
        domain: inferredDomain,
        seed: i,
      );

      final afterScore = QaHeuristicsEngine.semanticScore(tc);
      final after = _semanticSnapshot(tc);

      if (actions.isNotEmpty && before != after) {
        c.repairedCount++;
        pipelineLog.recordRepairTransform(
          tc.id.isNotEmpty ? tc.id : tc.title,
          before,
          after,
          'semantic_recovery',
          [
            'semantic_score $beforeScore->$afterScore',
            if (beforeRejection != null)
              'pre_repair_rejection: $beforeRejection',
            ...actions,
          ],
        );
      }

      recovered.add(tc);
    }

    return recovered;
  }

  List<String> _repairSemanticCase(
    TestCaseModel tc, {
    required String module,
    required String feature,
    required String platform,
    required String domain,
    required int seed,
  }) {
    final actions = <String>[];
    final category = _canonicalCategory(tc);
    final smoothFeature = _semanticSubject(module, feature);

    if (_isWeakSemanticTitle(tc.title)) {
      tc.title = _semanticTitle(
        category: category,
        feature: smoothFeature,
        platform: platform,
        seed: seed,
      );
      actions.add('rewrote weak title');
    }

    if (tc.preconditions.isEmpty ||
        tc.preconditions.every((p) => p.trim().length < 12)) {
      tc.preconditions = [
        'The $smoothFeature workflow is available in the $platform QA environment.',
      ];
      actions.add('recovered contextual preconditions');
    }

    final dataHint = _semanticDataHint(
      tc,
      category,
      platform,
      smoothFeature,
      seed,
    );
    final repairedSteps = _semanticSteps(
      category: category,
      platform: platform,
      feature: smoothFeature,
      dataHint: dataHint,
      seed: seed,
    );

    for (var i = 0; i < tc.steps.length; i++) {
      final fallback = repairedSteps[i % repairedSteps.length];
      final step = tc.steps[i];
      var changed = false;

      if (_isWeakStepAction(step.action)) {
        step.action = fallback.action;
        changed = true;
      }

      if (step.data.trim().isEmpty && fallback.data.trim().isNotEmpty) {
        step.data = fallback.data;
        changed = true;
      }

      if (_isWeakStepExpected(step.expected)) {
        step.expected = fallback.expected;
        changed = true;
      }

      if (changed) {
        actions.add('repaired step ${i + 1}');
      }
    }

    while (tc.steps.length < 3) {
      final fallback = repairedSteps[tc.steps.length % repairedSteps.length];
      tc.steps.add(
        TestStep(
          action: fallback.action,
          data: fallback.data,
          expected: fallback.expected,
        ),
      );
      actions.add('added executable step ${tc.steps.length}');
    }

    if (tc.expectedResult.trim().length < 60 ||
        QaHeuristicsEngine.hasWeakExpectedResult(tc.expectedResult) ||
        _hasSemanticMismatch(tc)) {
      tc.expectedResult = QaHeuristicsEngine.expectedResult(
        platform: platform,
        category: category,
        module: module,
        feature: feature,
        title: tc.title,
        domain: domain,
      );
      actions.add('rewrote weak expected result');
    }

    _normalizeCanonicalCase(
      tc,
      module: module,
      feature: feature,
      platform: platform,
      domain: domain,
    );

    return actions;
  }

  String _semanticSubject(String module, String feature) {
    final subject = _smooth(feature).trim().isNotEmpty
        ? _smooth(feature)
        : _smooth(module);
    return subject.trim().isNotEmpty ? subject.trim() : 'target feature';
  }

  bool _isWeakSemanticTitle(String title) {
    final text = title.toLowerCase().trim();
    if (text.length < 15) return true;

    const weakTitles = [
      'workflow stability',
      'default stability',
      'stability variant',
      'verify system',
      'perform action',
      'check functionality',
      'scenario 1',
      'scenario 2',
    ];

    return weakTitles.any(text.contains);
  }

  String _semanticTitle({
    required String category,
    required String feature,
    required String platform,
    required int seed,
  }) {
    final suffix = seed > 0 ? ' path ${seed + 1}' : '';
    switch (category) {
      case 'security':
        return 'Verify $feature blocks unsafe input without exposing protected data$suffix';
      case 'negative':
        return 'Verify $feature rejects invalid input while preserving user state$suffix';
      case 'validation':
        return 'Verify $feature enforces required field validation before submission$suffix';
      case 'boundary':
        return 'Verify $feature enforces input limits without data loss$suffix';
      case 'session':
        return 'Verify $feature maintains the correct session state across navigation$suffix';
      case 'usability':
        return 'Verify $feature supports accessible completion with visible feedback$suffix';
      case 'network_behavior':
        return 'Verify $feature handles interrupted connectivity with recoverable state$suffix';
      default:
        return 'Verify $feature completes the $platform workflow with observable confirmation$suffix';
    }
  }

  bool _isWeakStepAction(String action) {
    final text = action.toLowerCase().trim();
    if (text.length < 8) return true;

    const weakActions = [
      'open app',
      'click button',
      'submit form',
      'perform action',
      'check result',
      'verify success',
      'inspect state',
      'observe page',
      'perform primary',
      'enter details',
    ];

    return weakActions.any(text.contains);
  }

  bool _isWeakStepExpected(String expected) {
    final text = expected.toLowerCase().trim();
    if (text.length < 35) return true;
    return QaHeuristicsEngine.hasWeakExpectedResult(expected);
  }

  String _semanticDataHint(
    TestCaseModel tc,
    String category,
    String platform,
    String feature,
    int seed,
  ) {
    for (final step in tc.steps) {
      final value = step.data.trim();
      if (value.isNotEmpty &&
          !_bannedPhrases.any(value.toLowerCase().contains)) {
        return value;
      }
    }

    if (platform == 'API') {
      return '{"email":"${TestDataFactory.validEmail('semantic-$seed')}","requestId":"qa-$seed"}';
    }

    if (category == 'security') {
      return TestDataFactory.xssPayload();
    }

    if (category == 'negative' || category == 'validation') {
      return TestDataFactory.invalidEmail('semantic-$seed');
    }

    if (category == 'boundary') {
      return 'QA-${feature.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}-$seed-${''.padRight(64, 'X')}';
    }

    return TestDataFactory.validEmail('semantic-$seed');
  }

  List<TestStep> _semanticSteps({
    required String category,
    required String platform,
    required String feature,
    required String dataHint,
    required int seed,
  }) {
    if (platform == 'API') {
      final endpoint = PlatformRules.apiEndpoint(feature);
      return [
        TestStep(
          action: 'Send the prepared request to $endpoint',
          data: dataHint,
          expected:
              'The service returns a documented response code and a parseable response body for the submitted request.',
        ),
        TestStep(
          action: 'Validate the response fields and error messaging',
          data: '',
          expected:
              'The response includes the required contract fields and communicates any validation failure without internal details.',
        ),
        TestStep(
          action: 'Verify downstream state after the API operation',
          data: '',
          expected:
              'The backend state matches the accepted or rejected request outcome and no unintended record is created.',
        ),
      ];
    }

    return [
      TestStep(
        action: 'Open the $feature workflow in a clean QA session',
        data: '',
        expected:
            'The workflow loads with the relevant controls visible and no stale user input carried from a previous run.',
      ),
      TestStep(
        action: _semanticInputAction(category, feature),
        data: dataHint,
        expected:
            'The interface accepts the entered value or marks the affected field with an observable validation state.',
      ),
      TestStep(
        action: _semanticSubmitAction(platform, feature, seed),
        data: '',
        expected:
            'The workflow displays a clear completion, rejection, or recovery state that matches the scenario intent.',
      ),
    ];
  }

  String _semanticInputAction(String category, String feature) {
    switch (category) {
      case 'security':
        return 'Enter the unsafe payload into the $feature input field';
      case 'negative':
      case 'validation':
        return 'Enter invalid values into the required $feature fields';
      case 'boundary':
        return 'Paste the boundary-length value into the $feature input field';
      default:
        return 'Enter valid values into the $feature input fields';
    }
  }

  String _semanticSubmitAction(String platform, String feature, int seed) {
    if (platform == 'Mobile') {
      return seed.isEven
          ? 'Tap the primary $feature action control'
          : 'Confirm the $feature action from the mobile screen';
    }
    return seed.isEven
        ? 'Submit the $feature workflow for processing'
        : 'Activate the primary $feature confirmation control';
  }

  String _semanticSnapshot(TestCaseModel tc) {
    return [
      'title=${tc.title}',
      'type=${tc.type}',
      'expected=${tc.expectedResult}',
      'steps=${tc.steps.map((s) => '${s.action}|${s.data}|${s.expected}').join(' :: ')}',
    ].join('\n');
  }

  List<String> _repairDuplicateIntent(
    TestCaseModel tc, {
    required String module,
    required String feature,
    required String platform,
    required String domain,
    required int seed,
  }) {
    final actions = <String>[];
    final category = _canonicalCategory(tc);
    final smoothFeature = _semanticSubject(module, feature);
    final variant = _semanticVariant(category, seed);

    tc.title =
        '${_semanticTitle(category: category, feature: smoothFeature, platform: platform, seed: seed)} using $variant';
    actions.add('rewrote duplicate title with variant focus: $variant');

    final dataHint = _semanticDataHint(
      tc,
      category,
      platform,
      smoothFeature,
      seed,
    );
    final steps = _semanticSteps(
      category: category,
      platform: platform,
      feature: smoothFeature,
      dataHint: dataHint,
      seed: seed,
    );

    tc.steps = steps;
    actions.add('rebuilt duplicate steps around variant focus');

    tc.expectedResult = QaHeuristicsEngine.expectedResult(
      platform: platform,
      category: category,
      module: module,
      feature: feature,
      title: tc.title,
      domain: domain,
    );
    actions.add('rebuilt duplicate expected result');

    _normalizeCanonicalCase(
      tc,
      module: module,
      feature: feature,
      platform: platform,
      domain: domain,
    );

    return actions;
  }

  String _semanticVariant(String category, int seed) {
    final variants = switch (category) {
      'security' => [
        'script payload coverage',
        'unauthorized session coverage',
        'sensitive data exposure coverage',
      ],
      'validation' => [
        'missing required value coverage',
        'invalid format coverage',
        'mixed valid and invalid field coverage',
      ],
      'boundary' => [
        'maximum length coverage',
        'minimum value coverage',
        'overflow input coverage',
      ],
      'session' => [
        'refresh state coverage',
        'logout state coverage',
        'concurrent session coverage',
      ],
      _ => [
        'valid input coverage',
        'invalid input coverage',
        'state preservation coverage',
      ],
    };

    return variants[seed % variants.length];
  }

  List<TestCaseModel> _qualityValidationStage({
    required List<TestCaseModel> cases,
    required String platform,
    required int targetCount,
    required String module,
    required String feature,
    required String inferredDomain,
    required PipelineLogger pipelineLog,
    required _PipelineCounters c,
  }) {
    final qualityFiltered = cases.where((tc) {
      final score = _qualityScore(tc);
      final semanticScore = QaHeuristicsEngine.semanticScore(tc);
      final canonicalRejection = _canonicalRejectionReason(tc, platform);
      if ((score >= 3 || semanticScore >= 3) && canonicalRejection == null) {
        pipelineLog.recordAcceptance(
          tc.title,
          'quality score ok ($score), semantic score ok ($semanticScore)',
        );
        return true;
      }
      pipelineLog.recordRejection(
        tc.title,
        canonicalRejection ?? 'quality score too low ($score)',
      );
      return false;
    }).toList();

    var next = qualityFiltered;

    // FALLBACK: replaces entire list when quality pipeline eliminates everything.
    if (next.isEmpty) {
      final failureReason =
          c.aiFailureReason ??
          'All generated cases failed canonical validation.';
      c.aiFailureReason = failureReason;
      pipelineLog.recordParseFailure(failureReason);
      next = FallbackGenerator.generate(
        count: targetCount,
        module: module,
        feature: feature,
        platform: platform,
      );
      c.fallbackUsed = true;
      for (final tc in next) {
        _normalizeCanonicalCase(
          tc,
          module: module,
          feature: feature,
          platform: platform,
          domain: inferredDomain,
        );
        pipelineLog.recordAcceptance(
          tc.title,
          'fallback canonical case accepted',
        );
      }
    }

    return next;
  }

  ({List<TestCaseModel> cases, int aiInputCount}) _deduplicationStage({
    required List<TestCaseModel> cases,
    required bool isProMode,
    required String module,
    required String feature,
    required String platform,
    required String inferredDomain,
    required PipelineLogger pipelineLog,
    required _PipelineCounters c,
  }) {
    final seenTitles = <String>{};
    final seenIntents = <String>{};
    final seenCategories = <String>{};
    final beforeDedup = cases.length;

    final requiredCategories = 8;
    final requiredVerbs = 12;
    final actionVerbs = <String>{};

    final result = <TestCaseModel>[];
    var duplicateAttempts = 0;

    for (final tc in cases) {
      final lower = tc.title.trim().toLowerCase();
      final intent = _intentSignature(tc);
      if (seenTitles.contains(lower) || seenIntents.contains(intent)) {
        final seed = beforeDedup + duplicateAttempts++;
        final before = _semanticSnapshot(tc);
        final actions = _repairDuplicateIntent(
          tc,
          module: module,
          feature: feature,
          platform: platform,
          domain: inferredDomain,
          seed: seed,
        );
        final repairedLower = tc.title.trim().toLowerCase();
        final repairedIntent = _intentSignature(tc);

        if (!seenTitles.contains(repairedLower) &&
            !seenIntents.contains(repairedIntent) &&
            _canonicalRejectionReason(tc, platform) == null) {
          c.repairedCount++;
          pipelineLog.recordDuplicateCluster([
            lower,
            repairedLower,
          ], 'duplicate intent repaired in place');
          pipelineLog.recordRepairTransform(
            tc.id.isNotEmpty ? tc.id : tc.title,
            before,
            _semanticSnapshot(tc),
            'duplicate_intent_recovery',
            actions,
          );
          seenTitles.add(repairedLower);
          seenIntents.add(repairedIntent);
          for (final s in tc.steps) {
            if (s.action.isNotEmpty) {
              actionVerbs.add(s.action.split(' ').first.toLowerCase());
            }
          }
          if (tc.type.isNotEmpty) {
            seenCategories.add(tc.type);
          }
          result.add(tc);
        }
        continue;
      }
      seenTitles.add(lower);
      seenIntents.add(intent);

      for (final s in tc.steps) {
        if (s.action.isNotEmpty) {
          actionVerbs.add(s.action.split(' ').first.toLowerCase());
        }
      }

      if (tc.type.isNotEmpty) {
        seenCategories.add(tc.type);
      }

      result.add(tc);
    }
    c.duplicatesRemovedCount += beforeDedup - result.length;
    pipelineLog.afterDedup = List.from(result);

    if (isProMode) {
      if (seenCategories.length < requiredCategories) {
        print(
          'PRO Mode Warning: Not enough distinct categories generated. Found: ${seenCategories.length}/${requiredCategories}.',
        );
      }
      if (actionVerbs.length < requiredVerbs) {
        print(
          'PRO Mode Warning: Not enough unique action verbs. Found: ${actionVerbs.length}/${requiredVerbs}.',
        );
      }
    }

    return (cases: result, aiInputCount: beforeDedup);
  }

  List<TestCaseModel> _deterministicRepairStage({
    required List<TestCaseModel> cases,
    required int maxCases,
    required ScenarioPlanner planner,
    required String module,
    required String feature,
    required String platform,
    required String inferredDomain,
    required PipelineLogger pipelineLog,
    required _PipelineCounters c,
  }) {
    final beforeRepair = cases.length;
    final repair = DeterministicRepair(planner);
    var next = repair.repair(cases, maxCases);

    // Log repairs
    for (final event in repair.repairEvents) {
      pipelineLog.recordRepairTransform(
        event.testCaseId,
        event.before,
        event.after,
        event.reason,
        [event.reason],
      );
    }
    for (final tc in next) {
      _normalizeCanonicalCase(
        tc,
        module: module,
        feature: feature,
        platform: platform,
        domain: inferredDomain,
      );
    }
    next = next
        .where((tc) => _canonicalRejectionReason(tc, platform) == null)
        .toList();
    c.repairedCount = next.length > beforeRepair
        ? next.length - beforeRepair
        : 0;
    pipelineLog.afterRepair = List.from(next);
    return next;
  }

  List<TestCaseModel> _deduplicateAfterRepairStage({
    required List<TestCaseModel> cases,
    required String module,
    required String feature,
    required String platform,
    required String inferredDomain,
    required PipelineLogger pipelineLog,
    required _PipelineCounters c,
  }) {
    final seenFinal = <String>{};
    final seenFinalIntents = <String>{};
    final beforeFinalDedup = List<TestCaseModel>.from(cases);

    final finalDeduped = <TestCaseModel>[];
    var duplicateAttempts = 0;
    for (final tc in cases) {
      final lower = tc.title.trim().toLowerCase();
      final intent = _intentSignature(tc);

      if (seenFinal.contains(lower) || seenFinalIntents.contains(intent)) {
        final seed =
            beforeFinalDedup.length +
            c.postRepairDuplicatesRemoved +
            duplicateAttempts++;
        final before = _semanticSnapshot(tc);
        final actions = _repairDuplicateIntent(
          tc,
          module: module,
          feature: feature,
          platform: platform,
          domain: inferredDomain,
          seed: seed,
        );
        final repairedLower = tc.title.trim().toLowerCase();
        final repairedIntent = _intentSignature(tc);

        if (seenFinal.contains(repairedLower) ||
            seenFinalIntents.contains(repairedIntent) ||
            _canonicalRejectionReason(tc, platform) != null) {
          c.postRepairDuplicatesRemoved++;
          pipelineLog.recordRejection(
            tc.title,
            'post-repair dedup removed duplicate title/intent',
          );
          continue;
        }

        c.repairedCount++;
        pipelineLog.recordRepairTransform(
          tc.id.isNotEmpty ? tc.id : tc.title,
          before,
          _semanticSnapshot(tc),
          'post_repair_duplicate_intent_recovery',
          actions,
        );
        seenFinal.add(repairedLower);
        seenFinalIntents.add(repairedIntent);
        finalDeduped.add(tc);
        continue;
      }

      seenFinal.add(lower);
      seenFinalIntents.add(intent);
      finalDeduped.add(tc);
    }

    if (finalDeduped.isNotEmpty) {
      cases = finalDeduped;
    } else {
      cases = beforeFinalDedup;
    }
    final afterIntentDedup = cases.length;
    c.duplicatesRemovedCount += beforeFinalDedup.length - afterIntentDedup;

    final uniqueHashes = <String>{};
    final deduped = <TestCaseModel>[];

    for (final tc in cases) {
      final hash =
          '''
      ${tc.title}
      ${tc.expectedResult}
      ${tc.steps.map((s) => '${s.action}|${s.data}|${s.expected}').join('|')}
      '''
              .toLowerCase()
              .trim();
      if (!uniqueHashes.contains(hash)) {
        uniqueHashes.add(hash);
        deduped.add(tc);
      } else {
        c.postRepairDuplicatesRemoved++;
        pipelineLog.recordRejection(
          tc.title,
          'post-repair dedup removed identical structure hash',
        );
      }
    }
    if (deduped.isNotEmpty) {
      final hashRemoved = cases.length - deduped.length;
      c.duplicatesRemovedCount += hashRemoved;
      cases = deduped;
    }

    if (c.postRepairDuplicatesRemoved > 0) {
      print(
        '[QA Genie Post-repair dedup] removed ${c.postRepairDuplicatesRemoved} case(s); see pipeline rejectedCases titles',
      );
    }

    return cases;
  }

  List<TestCaseModel> _fallbackFillStage({
    required List<TestCaseModel> cases,
    required int targetCount,
    required String module,
    required String feature,
    required String platform,
    required String inferredDomain,
    required _PipelineCounters c,
  }) {
    return _fillCanonicalGaps(
      current: cases,
      targetCount: targetCount,
      module: module,
      feature: feature,
      platform: platform,
      domain: inferredDomain,
    );
  }

  /// **Sole export invariant gate:** enforces `[0, targetCount]` truncation, assigns the
  /// authoritative export identifiers, persists pipeline debug (`bypassPipeline` uses
  /// [IdGenerator] IDs without the late normalization applied to shipped runs).
  Future<List<TestCaseModel>> _finalInvariantStage({
    required List<TestCaseModel> cases,
    required int targetCount,
    required String module,
    required String feature,
    required String platform,
    required String inferredDomain,
    required bool bypassPipeline,
    required int startIndex,
    required PipelineLogger pipelineLog,
    _PipelineCounters? counters,
  }) async {
    if (bypassPipeline) {
      // IDs run over the ENTIRE staged list before logging / truncation (historic behavior).
      for (int i = 0; i < cases.length; i++) {
        cases[i].id = IdGenerator.generate(module, feature, startIndex + i);
      }
      _compressFinalExpectedText(cases);
      pipelineLog.finalCases = List.from(cases);
      pipelineLog.rawAiResponse = PipelineDebugStore.lastRawResponse;
      pipelineLog.cleanedAiResponse = PipelineDebugStore.lastCleanedResponse;
      pipelineLog.finalApiPrompt = PipelineDebugStore.lastFinalPrompt;
      pipelineLog.writeToDisk().catchError((_) {});
      return cases.take(targetCount).toList();
    }

    // QUALITY-AWARE PRIORITY ENFORCEMENT & MINIMAL EMERGENCY FILL
    var next = _enforcePriorityDistribution(
      cases,
      targetCount,
      module,
      feature,
      platform,
      inferredDomain,
    );

    final c = counters!;

    for (int i = 0; i < next.length; i++) {
      final tc = next[i];
      final originalTitle = tc.title;
      final originalExpected = tc.expectedResult;

      tc.title = QaRealismEnforcer.humanizeTitle(tc.title, '$module $feature');
      tc.expectedResult = QaRealismEnforcer.humanizeExpectedResult(
        tc.expectedResult, 
        '$module $feature',
        intent: tc.intent,
        platform: platform,
      );

      if (tc.title != originalTitle || tc.expectedResult != originalExpected) {
        PipelineDebugStore.realismInjections.add({
          'id': tc.id,
          'before': {
            'title': originalTitle,
            'expectedResult': originalExpected,
          },
          'after': {
            'title': tc.title,
            'expectedResult': tc.expectedResult,
          },
        });
      }

      for (final s in tc.steps) {
        s.expected = QaRealismEnforcer.humanizeStepExpectation(s.expected, '$module $feature');
      }

      _normalizeCanonicalCase(
        tc,
        module: module,
        feature: feature,
        platform: platform,
        domain: inferredDomain,
      );
      
      // ABSOLUTE FINAL STEP: SEQUENTIAL ID ASSIGNMENT
      next[i].id =
          'TC_${module.toUpperCase().replaceAll(RegExp(r"[^A-Z0-9]+"), "_")}_${(i + 1).toString().padLeft(3, '0')}';
    }

    _compressFinalExpectedText(next);
    
    // Final user-visible objects
    PipelineDebugStore.finalObjects = next.map((e) => e.toJson()).toList();

    pipelineLog.aiFailure = c.aiFailureReason != null;
    pipelineLog.finalCases = List.from(next);
    pipelineLog.fallbackUsed = c.fallbackUsed;
    pipelineLog.aiGenerated = c.aiGenerated;
    pipelineLog.accepted = c.aiAccepted;
    pipelineLog.repaired = c.repairedCount;
    pipelineLog.filtered = c.filteredCount;
    pipelineLog.duplicatesRemoved = c.duplicatesRemovedCount;
    pipelineLog.rawAiResponse = PipelineDebugStore.lastRawResponse;
    pipelineLog.cleanedAiResponse = PipelineDebugStore.lastCleanedResponse;
    pipelineLog.finalApiPrompt = PipelineDebugStore.lastFinalPrompt;

    pipelineLog.writeToDisk().catchError((_) {});

    final beforeValidation = next.length;
    next = next.where((tc) => StructuralCaseValidator.isValid(tc.toJson())).toList();
    PipelineDebugStore.invalidCasesDropped = beforeValidation - next.length;

    final realismScore = QaRealismEnforcer.validateSuite(next, platform);
    print('PRODUCTION REALISM SCORE: $realismScore');

    // Deterministic Forensic Recording
    final tier = targetCount > 8 ? 'pro' : 'core';
    
    final lineage = _finalSuiteOriginTally(next);
    PipelineDebugStore.finalAiCases = lineage.ai;
    PipelineDebugStore.finalFallbackCases = lineage.fallback;
    PipelineDebugStore.cleanerRepairCount = lineage.detRepair;

    final forensics = GenerationForensicRecorder.captureCurrentForensics(
      realismScore: realismScore,
      tier: tier,
      platform: platform,
    );
    
    await GenerationForensicRecorder.recordPipelineLog(tier).catchError((_) {});
    await GenerationForensicRecorder.recordAnalyticalLog(tier, forensics).catchError((_) {});

    return next.take(targetCount).toList();
  }

  String _categoryToType(String cat) {
    switch (cat) {
      case 'positive':
        return 'POSITIVE';
      case 'negative':
        return 'NEGATIVE';
      case 'security':
        return 'SECURITY';
      case 'boundary':
        return 'EDGE';
      case 'validation':
        return 'VALIDATION';
      case 'session':
        return 'SESSION';
      case 'usability':
        return 'USABILITY';
      case 'network_behavior':
        return 'NETWORK';
      default:
        return 'GENERAL';
    }
  }

  String _smooth(String feature) {
    return feature
        .replaceAll(
          RegExp(r' with email and password', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r' using email and password', caseSensitive: false),
          '',
        )
        .trim();
  }

  void _normalizeCanonicalCase(
    TestCaseModel tc, {
    required String module,
    required String feature,
    required String platform,
    required String domain,
  }) {
    // Phase H: Keep metadata pruned
    tc.module = '';
    tc.feature = '';
    tc.platform = '';
    tc.actualResult = '';
    tc.status = '';

    final category = _canonicalCategory(tc);
    tc.type = _categoryToType(category);
    
    // Only infer priority if not already explicitly set to a valid value
    if (!['High', 'Medium', 'Low'].contains(tc.priority)) {
      tc.priority = _riskPriority(tc, module, feature, platform, domain);
    }

    final smoothFeature = _smooth(feature);
    final genericPreconditions = {
      'standard qa environment',
      'application is accessible and stable',
    };
    if (tc.preconditions.isEmpty ||
        tc.preconditions.every(
          (p) => genericPreconditions.contains(p.trim().toLowerCase()),
        )) {
      tc.preconditions = [
        'The $smoothFeature interface is available in the $platform QA environment.',
      ];
    }

    for (final step in tc.steps) {
      if (step.action.trim().isEmpty) {
        step.action =
            'Perform the primary $smoothFeature action for this scenario';
      }
      if (step.expected.trim().isEmpty ||
          QaHeuristicsEngine.hasWeakExpectedResult(step.expected)) {
        step.expected = _stepExpectedForCategory(category, smoothFeature);
      }
    }

    if (tc.steps.isEmpty) {
      tc.steps.add(
        TestStep(
          action: 'Perform the primary $smoothFeature action for this scenario',
          data: '',
          expected: 'The system responds with the expected business outcome',
        ),
      );
    }

    if (tc.expectedResult.trim().isEmpty ||
        QaHeuristicsEngine.hasWeakExpectedResult(tc.expectedResult) ||
        _hasSemanticMismatch(tc)) {
      tc.expectedResult = QaHeuristicsEngine.expectedResult(
        platform: platform,
        category: category,
        module: module,
        feature: feature,
        title: tc.title,
        domain: domain,
      );
    }
  }

  String _canonicalCategory(TestCaseModel tc) {
    final raw = '${tc.type} ${tc.title}'.toLowerCase();
    if (raw.contains('positive')) return 'positive';
    if (raw.contains('negative')) return 'negative';
    if (raw.contains('security') ||
        raw.contains('xss') ||
        raw.contains('sql') ||
        raw.contains('csrf') ||
        raw.contains('tamper')) {
      return 'security';
    }
    if (raw.contains('session') ||
        raw.contains('logout') ||
        raw.contains('timeout') ||
        raw.contains('refresh')) {
      return 'session';
    }
    if (raw.contains('validation') ||
        raw.contains('required') ||
        raw.contains('format') ||
        raw.contains('missing')) {
      return 'validation';
    }
    if (raw.contains('edge') ||
        raw.contains('boundary') ||
        raw.contains('length') ||
        raw.contains('limit')) {
      return 'boundary';
    }
    if (raw.contains('usability') ||
        raw.contains('accessibility') ||
        raw.contains('keyboard') ||
        raw.contains('screen reader')) {
      return 'usability';
    }
    if (raw.contains('network') ||
        raw.contains('retry') ||
        raw.contains('connectivity')) {
      return 'network_behavior';
    }
    return QaHeuristicsEngine.inferCategory(tc.type, tc.title);
  }

  String _stepExpectedForCategory(String category, String feature) {
    switch (category) {
      case 'security':
        return 'The application rejects the risky input without exposing sensitive data, debug details, or an authenticated state.';
      case 'negative':
        return 'A specific error message is displayed and the user remains in the current unauthenticated workflow state.';
      case 'validation':
        return 'A field-level validation message appears beside the affected input and submission remains blocked.';
      case 'boundary':
        return 'The input constraint is enforced visibly without layout distortion or hidden data loss.';
      case 'session':
        return 'The visible session state changes according to the scenario and protected content remains controlled.';
      case 'usability':
        return 'The control remains reachable and gives visible feedback that a tester can observe without ambiguity.';
      case 'network_behavior':
        return 'The workflow displays a retry, completion, or validation state without losing the submitted data.';
      default:
        return 'The $feature workflow displays a clear final state with the submitted data preserved or validated.';
    }
  }

  String? _canonicalRejectionReason(TestCaseModel tc, String platform) {
    if (_containsGarbage(tc)) return 'contains placeholder or filler wording';
    if (_violatesPlatform(tc, platform))
      return 'contains terminology for a different platform';
    final lowerTitle = tc.title.toLowerCase();
    if (lowerTitle.contains('workflow stability') ||
        lowerTitle.contains('default stability') ||
        lowerTitle.contains('stability variant') ||
        lowerTitle.contains('variant ')) {
      return 'title is generic or a stability variant';
    }
    if (tc.title.trim().length < 8) return 'title is too short';
    if (tc.preconditions.isEmpty) return 'missing preconditions';
    if (tc.steps.length < 3) return 'fewer than three executable steps';
    if (tc.expectedResult.trim().length < 60) {
      return 'final expected result is too short for export-safe execution';
    }
    if (QaHeuristicsEngine.hasWeakExpectedResult(tc.expectedResult)) {
      return 'final expected result is weak or generic';
    }
    if (_hasSemanticMismatch(tc))
      return 'title and expected result describe different intents';

    final featureContext = '${tc.module} ${tc.feature}'.toLowerCase();
    final combined =
        '${tc.title} ${tc.expectedResult} ${tc.steps.map((s) => '${s.action} ${s.data} ${s.expected}').join(' ')}'
            .toLowerCase();
    if (featureContext.contains('login') &&
        (combined.contains('checkout') ||
            combined.contains('payment') ||
            combined.contains('card') ||
            combined.contains('order') ||
            combined.contains('age:') ||
            combined.contains('numeric input'))) {
      return 'scenario is not relevant to login/authentication';
    }

    for (var i = 0; i < tc.steps.length; i++) {
      final step = tc.steps[i];
      if (step.action.trim().length < 8) {
        return 'step ${i + 1} action is too short';
      }
      if (step.expected.trim().length < 35) {
        return 'step ${i + 1} expected result is too short';
      }
      if (QaHeuristicsEngine.hasWeakExpectedResult(step.expected)) {
        return 'step ${i + 1} expected result is weak or generic';
      }
    }

    return null;
  }

  bool _hasSemanticMismatch(TestCaseModel tc) {
    final title = tc.title.toLowerCase();
    final expected = tc.expectedResult.toLowerCase();
    if ((title.contains('persist') || title.contains('refresh')) &&
        (expected.contains('session expiry') ||
            expected.contains('upon session expiry') ||
            expected.contains('redirects the user to the login page'))) {
      return true;
    }
    if (title.contains('invalid') &&
        expected.contains('opens the authenticated destination')) {
      return true;
    }
    if (title.contains('missing') &&
        expected.contains('success notification')) {
      return true;
    }
    return false;
  }

  List<TestCaseModel> _fillCanonicalGaps({
    required List<TestCaseModel> current,
    required int targetCount,
    required String module,
    required String feature,
    required String platform,
    required String domain,
  }) {
    final result = <TestCaseModel>[];
    final seenTitles = <String>{};
    final seenIntents = <String>{};

    void addIfUsable(TestCaseModel tc) {
      if (result.length >= targetCount) return;
      _normalizeCanonicalCase(
        tc,
        module: module,
        feature: feature,
        platform: platform,
        domain: domain,
      );
      if (_canonicalRejectionReason(tc, platform) != null) return;
      final title = tc.title.toLowerCase().trim();
      final intent = _intentSignature(tc);
      if (seenTitles.contains(title) || seenIntents.contains(intent)) return;
      seenTitles.add(title);
      seenIntents.add(intent);
      result.add(tc);
    }

    for (final tc in current) {
      addIfUsable(tc);
    }

    final missing = targetCount - result.length;
    if (missing > 0) {
      final fallback = FallbackGenerator.generate(
        count: missing,
        module: module,
        feature: feature,
        platform: platform,
      );
      for (final tc in fallback) {
        addIfUsable(tc);
      }
    }

    var emergencyIndex = 0;
    var guard = 0;
    while (result.length < targetCount && guard < targetCount * 4) {
      guard++;
      addIfUsable(
        _emergencyCase(module, feature, platform, domain, emergencyIndex++),
      );
    }

    return result.take(targetCount).toList();
  }

  List<TestCaseModel> _enforcePriorityDistribution(
    List<TestCaseModel> cases,
    int targetCount,
    String module,
    String feature,
    String platform,
    String domain,
  ) {
    // -------------------------------
    // TARGET DISTRIBUTION
    // -------------------------------
    final lowTarget = (targetCount * 0.7).round();
    final mediumTarget = (targetCount * 0.2).round();
    final highTarget = targetCount - lowTarget - mediumTarget;

    // -------------------------------
    // BUCKETS
    // -------------------------------
    final low = <TestCaseModel>[];
    final medium = <TestCaseModel>[];
    final high = <TestCaseModel>[];
    final unknown = <TestCaseModel>[];

    for (final tc in cases) {
      final p = tc.priority.trim().toLowerCase();
      switch (p) {
        case 'low':
          low.add(tc);
          break;
        case 'medium':
          medium.add(tc);
          break;
        case 'high':
          high.add(tc);
          break;
        default:
          unknown.add(tc);
      }
    }

    // -------------------------------
    // NORMALIZE UNKNOWN PRIORITIES
    // -------------------------------
    for (final tc in unknown) {
      medium.add(tc.copyWith(priority: 'Medium'));
    }

    // -------------------------------
    // QUALITY SORT
    // IMPORTANT:
    // Highest quality survives trimming
    // -------------------------------
    int score(TestCaseModel tc) {
      int s = 0;
      if (tc.steps.length >= 3) s += 2;
      if (tc.expectedResult.trim().isNotEmpty) s += 2;
      if (tc.title.length > 15) s += 1;
      if (tc.preconditions.isNotEmpty) s += 1;
      if (tc.type.toLowerCase().contains('positive')) s += 2;
      if (tc.type.toLowerCase().contains('validation')) s += 1;
      return s;
    }

    void sortBucket(List<TestCaseModel> bucket) {
      bucket.sort((a, b) => score(b).compareTo(score(a)));
    }

    sortBucket(low);
    sortBucket(medium);
    sortBucket(high);

    // -------------------------------
    // SOFT TOLERANCE
    // Prevents fake forced balancing
    // -------------------------------
    final lowMin = lowTarget - 1;
    final mediumMin = mediumTarget - 1;
    final highMin = highTarget - 1;

    // -------------------------------
    // EMERGENCY GENERATOR
    // ONLY used when severely missing
    // -------------------------------
    TestCaseModel generateCase(
      String priority,
      String category,
    ) {
      return _emergencyCase(
        module,
        feature,
        platform,
        domain,
        cases.length + Random().nextInt(999),
        priority: priority,
        forcedCategory: category,
      );
    }

    // -------------------------------
    // CRITICAL GAP FILL ONLY
    // -------------------------------
    while (low.length < lowMin) {
      low.add(generateCase('Low', 'positive'));
    }
    while (medium.length < mediumMin) {
      medium.add(generateCase('Medium', 'negative'));
    }
    while (high.length < highMin) {
      high.add(generateCase('High', 'boundary'));
    }

    // -------------------------------
    // BUILD FINAL LIST
    // -------------------------------
    final result = <TestCaseModel>[];
    result.addAll(low.take(lowTarget));
    result.addAll(medium.take(mediumTarget));
    result.addAll(high.take(highTarget));

    // -------------------------------
    // FILL REMAINING SLOTS
    // WITH BEST LEFTOVER CASES
    // -------------------------------
    final leftovers = <TestCaseModel>[
      ...low.skip(lowTarget),
      ...medium.skip(mediumTarget),
      ...high.skip(highTarget),
    ];
    sortBucket(leftovers);

    for (final tc in leftovers) {
      if (result.length >= targetCount) break;
      result.add(tc);
    }

    // -------------------------------
    // FINAL HARD GUARANTEE
    // ALWAYS EXACTLY 8 / 16
    // -------------------------------
    while (result.length < targetCount) {
      result.add(
        generateCase('Medium', 'negative'),
      );
    }

    // -------------------------------
    // FINAL QUALITY SORT
    // -------------------------------
    sortBucket(result);

    return result.take(targetCount).toList();
  }

  TestCaseModel _emergencyCase(
    String module,
    String feature,
    String platform,
    String domain,
    int index, {
    String? priority,
    String? forcedCategory,
  }) {
    final templates = <String, Map<String, dynamic>>{};
    final smoothFeature = _smooth(feature);

    if (platform == 'Web') {
      templates.addAll({
        'web_negative': {
          'title':
              'Verify $smoothFeature rejects invalid credentials with specific on-screen error states',
          'category': 'negative',
          'data': '{invalidEmail} / {invalidPassword}',
          'expected':
              'A clear validation message appears below the affected fields, the submission control is disabled, and the application remains in the current state.',
          'preconditions': [
            'The $smoothFeature screen is open in a fresh application session.',
          ],
        },
        'web_boundary': {
          'title':
              'Verify $smoothFeature input fields enforce character limits without layout disruptions',
          'category': 'boundary',
          'data': 'A string exceeding the 255-character threshold',
          'expected':
              'The input field prevents additional characters and displays a validation indicator without breaking the screen layout.',
          'preconditions': [
            'The $smoothFeature screen is viewed on a standard desktop resolution.',
          ],
        },
        'web_xss': {
          'title':
              'Verify $smoothFeature form handles potentially unsafe script payloads securely',
          'category': 'security',
          'data': '{xssPayload}',
          'expected':
              'The application handles the input safely by rendering it as plain text and preventing any unintended script execution.',
          'preconditions': [
            'The $smoothFeature screen is in its default state.',
          ],
        },
        'web_session': {
          'title':
              'Verify $smoothFeature session persistence across navigation events',
          'category': 'session',
          'data': '',
          'expected':
              'The application maintains the user authentication state and restores the $smoothFeature view after a screen refresh.',
          'preconditions': [
            'The user has an active session with the application.',
          ],
        },
        'web_usability': {
          'title':
              'Verify $smoothFeature accessibility via keyboard navigation',
          'category': 'usability',
          'data': '',
          'expected':
              'Interactive elements receive visible focus indicators and the $smoothFeature workflow can be completed using only the keyboard.',
          'preconditions': [
            'The screen is in its default state and no pointer device is used.',
          ],
        },
      });
    }

    if (platform == 'API') {
      final authPrecondition = domain == 'auth'
          ? 'The API endpoint is reachable and the environment is stable.'
          : 'A valid authentication token is included in the request headers.';

      templates.addAll({
        'api_positive': {
          'title':
              'Verify $smoothFeature endpoint returns a success status with the correct response format',
          'category': 'positive',
          'data': '{"email":"{validEmail}","token":"{validToken}"}',
          'expected':
              'The service returns a successful confirmation and the resource is updated.',
          'preconditions': [authPrecondition],
        },
        'api_negative': {
          'title': 'Verify $smoothFeature handling of invalid inputs',
          'category': 'negative',
          'data': '{"email":"invalid-format","unexpected_key":true}',
          'expected':
              'The service returns a clear error notification identifying the input failure, and the system remains in the original state.',
          'preconditions': [authPrecondition],
        },
        'api_security': {
          'title':
              'Verify $smoothFeature blocks requests with invalid credentials',
          'category': 'security',
          'data': '{expiredToken}',
          'expected':
              'The service denies access and ensures the security of the resource.',
          'preconditions': [
            'The request is sent with an invalid or unauthorized session identifier.',
          ],
        },
        'api_rate_limit': {
          'title': 'Verify $smoothFeature manages request frequency',
          'category': 'security',
          'data': '',
          'expected':
              'The service prevents excessive requests and provides feedback about the limitation.',
          'preconditions': [
            'The client sends requests exceeding the allowed threshold.',
          ],
        },
      });
    }

    if (platform == 'Mobile') {
      templates.addAll({
        'mobile_positive': {
          'title':
              'Verify $smoothFeature workflow completion with visual feedback',
          'category': 'positive',
          'data': '{validEmail} / {validPassword}',
          'expected':
              'The flow completes with a success indicator, visual feedback is provided, and the navigation state is updated.',
          'preconditions': ['The app is running on a standard mobile device.'],
        },
        'mobile_negative': {
          'title':
              'Verify $smoothFeature handles connectivity issues during data submission',
          'category': 'negative',
          'data': '{validEmail}',
          'expected':
              'The app detects the operation timeout, displays an actionable retry notification, and preserves the user input.',
          'preconditions': [
            'The device is configured with a limited or unstable connection.',
          ],
        },
        'mobile_session': {
          'title':
              'Verify $smoothFeature state restoration after app backgrounding',
          'category': 'session',
          'data': '',
          'expected':
              'Upon resuming from the background, the $smoothFeature screen remains accessible without an unintended application restart.',
          'preconditions': [
            'The app is moved to the background while on the $smoothFeature screen.',
          ],
        },
      });
    }

    if (templates.isEmpty) {
      templates.addAll({
        'default': {
          'title': 'Verify $smoothFeature default workflow stability',
          'category': 'positive',
          'data': '{validEmail}',
          'expected':
              'The flow completes and the user is presented with the next logical step.',
          'preconditions': ['The $smoothFeature interface is accessible.'],
        },
      });
    }

    final keys = templates.keys.toList();
    final key = keys[index % keys.length];
    final tpl = templates[key]!;

    final titleRaw = tpl['title'] as String;
    final title = '$titleRaw (recovery ${index + 1})';
    final category = forcedCategory ?? (tpl['category'] as String);
    final rawData = (tpl['data'] as String);
    final data = rawData.isNotEmpty
        ? rawData
              .replaceAll(
                '{validEmail}',
                TestDataFactory.validEmail('emergency-$index'),
              )
              .replaceAll(
                '{invalidEmail}',
                TestDataFactory.invalidEmail('emergency-$index'),
              )
              .replaceAll(
                '{validPassword}',
                TestDataFactory.validPassword('emergency-$index'),
              )
              .replaceAll(
                '{invalidPassword}',
                TestDataFactory.invalidPassword('emergency-$index'),
              )
              .replaceAll('{xssPayload}', TestDataFactory.xssPayload())
              .replaceAll('{validToken}', TestDataFactory.validToken())
              .replaceAll('{expiredToken}', TestDataFactory.expiredToken())
        : '';
    final expected = (tpl['expected'] as String);
    final preconditions = (tpl['preconditions'] as List).cast<String>();

    final steps = _buildEmergencySteps(platform, smoothFeature, data, index);

    final tc = TestCaseModel(
      source: CaseSource.fallback,
      title: title,
      module: module,
      feature: feature,
      platform: platform,
      preconditions: preconditions.map((e) => _cleanGeneratedText(e)).toList(),
      steps: steps,
      expectedResult: _smartExpectedResult(title, expected),
      priority: 'Medium', // Placeholder
      type: _categoryToType(category),
    );

    final finalPriority =
        priority ?? _riskPriority(tc, module, feature, platform, domain);

    return tc.copyWith(priority: finalPriority);
  }

  List<TestStep> _buildEmergencySteps(
    String platform,
    String feature,
    String data,
    int seed,
  ) {
    final idx = StableHash.forText('emergency-step-$seed', 3);
    switch (platform) {
      case 'API':
        final endpoint = PlatformRules.apiEndpoint(feature);
        return [
          TestStep(
            action: 'Send request to $endpoint',
            data: data,
            expected:
                'The API returns the expected status code and response payload structure',
          ),
          TestStep(
            action: 'Validate response status and schema',
            data: '',
            expected: 'Response structure matches expected API contract',
          ),
          TestStep(
            action: 'Validate backend persistence and validation behavior',
            data: '',
            expected: 'Backend state changes are processed correctly',
          ),
        ];
      case 'Mobile':
        final openActions = [
          'Open the $feature screen from the app menu',
          'Tap the $feature icon in the navigation bar',
          'Launch the $feature view from the home screen',
        ];
        final triggerActions = [
          'Tap the primary action button',
          'Swipe to trigger the main flow',
          'Use the confirm action on the screen',
        ];
        return [
          TestStep(
            action: openActions[idx],
            data: '',
            expected: 'The $feature screen loads with all controls visible',
          ),
          TestStep(
            action: 'Enter the provided test data into the relevant fields',
            data: data,
            expected: 'Each field accepts input without crashing',
          ),
          TestStep(
            action: triggerActions[idx],
            data: '',
            expected:
                'The app responds with visual feedback and remains responsive',
          ),
        ];
      default:
        final openActions = [
          'Open the $feature screen in a supported application',
          'Navigate to the $feature URL in a fresh application tab',
          'Load the $feature screen from the application menu',
        ];
        final submitActions = [
          'Submit the $feature form',

          'Click the primary action button',

          'Complete the $feature workflow',
        ];
        return [
          TestStep(
            action: openActions[idx],
            data: '',
            expected: 'The $feature screen loads successfully',
          ),
          TestStep(
            action: 'Enter the provided test data into the relevant fields',
            data: data,
            expected:
                'The application accepts the provided input and updates the workflow state correctly',
          ),
          TestStep(
            action: submitActions[idx],
            data: '',
            expected:
                'The application updates the visible workflow state, preserves submitted data correctly, and displays the expected completion state',
          ),
        ];
    }
  }

  String _riskPriority(
    TestCaseModel tc,
    String module,
    String feature,
    String platform,
    String domain,
  ) {
    final category = QaHeuristicsEngine.inferCategory(tc.type, tc.title);
    final priority = QaHeuristicsEngine.priorityFor(
      category: category,
      module: tc.module.isNotEmpty ? tc.module : module,
      feature: tc.feature.isNotEmpty ? tc.feature : feature,
      title: tc.title,
      platform: tc.platform.isNotEmpty ? tc.platform : platform,
      domain: domain,
    );
    return PriorityUtils.normalize(priority);
  }

  String _expertExpectedResult(
    TestCaseModel tc,
    String module,
    String feature,
    String platform,
    String domain,
  ) {
    final title = tc.title.toLowerCase();
    final category = tc.type.toLowerCase();

    if (title.contains('login') || category.contains('auth')) {
      return platform == 'API'
          ? 'Authentication response returns valid token structure and unauthorized access remains blocked securely'
          : 'User session starts and unauthorized access remains restricted throughout the workflow';
    }

    if (title.contains('payment')) {
      return platform == 'API'
          ? 'Payment transaction persists without duplicate processing or inconsistent transaction state'
          : 'Payment  and transaction status is reflected accurately in the interface';
    }

    if (title.contains('scroll')) {
      return 'Application remains responsive during extended scrolling without frame drops, crashes, or rendering instability';
    }

    if (title.contains('permission') || title.contains('biometric')) {
      return 'Security validation flow behaves and invalid authentication attempts are handled safely';
    }

    if (title.contains('phone') ||
        title.contains('validation') ||
        title.contains('format')) {
      return 'Invalid input is rejected with meaningful validation feedback while maintaining stable application behavior';
    }

    return platform == 'API'
        ? 'API validation, response structure, and backend persistence behave consistently under the executed scenario'
        : 'Workflow completes and application state remains and stable after interaction';
  }

  String _buildEnrichmentPrompt(
    List<Map<String, dynamic>> skeletons,
    String module,
    String feature,
    String platform,
  ) {
    final sb = StringBuffer();

    sb.writeln('(Prompt centralized in system_prompt.dart) v$PROMPT_VERSION');
    sb.writeln('Module: $module | Feature: $feature | Platform: $platform');
    sb.writeln('Return up to ${skeletons.length} ordered JSON cases.');
    sb.writeln('Preserve scenario intent.');

    for (final sk in skeletons) {
      sb.writeln('- ${sk['title']} (${sk['category']}, type: ${sk['type']})');
    }
    sb.writeln(SystemPrompt.platformRules(platform));

    return sb.toString();
  }

  void _compressFinalExpectedText(List<TestCaseModel> cases) {
    for (final tc in cases) {
      tc.expectedResult = compressExpected(tc.expectedResult);
      for (final step in tc.steps) {
        step.action = _cleanFinalActionText(step.action);
        step.expected = compressExpected(step.expected);
      }
    }
  }

  String _cleanFinalActionText(String text) {
    return text
        .replaceAll(RegExp(r'\b[Ii]nspect\b'), 'Review')
        .replaceAll(RegExp(r'\b[Oo]bserve\b'), 'Confirm')
        .replaceAll(RegExp(r'\b[Pp]erform action\b'), 'Complete workflow')
        .replaceAll(RegExp(r'\b[Cc]heck result\b'), 'Validate outcome')
        .replaceAll(RegExp(r'\b[Vv]erify system\b'), 'Validate workflow')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String compressExpected(String text) {
    return text
        .replaceAll(RegExp(r'\b[Tt]he system\b'), '')
        .replaceAll(RegExp(r'\b[Tt]he application\b'), '')
        .replaceAll('displays', 'shows')
        .replaceAll('successfully', '')
        .replaceAll('is redirected to', 'redirects to')
        .replaceAll('The user', '')
        .replaceAll('user is', '')
        .replaceAll('validation message', 'error')
        .replaceAll('error message', 'error')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _cleanGeneratedText(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' ,', ',')
        .replaceAll(' .', '.')
        .trim();
  }

  String _smartExpectedResult(String title, String expected) {
    final lower = title.toLowerCase();

    final isNegative = [
      "invalid",
      "expired",
      "unauthorized",
      "malformed",
      "blocked",
      "rate limit",
      "reject",
      "denied",
    ].any(lower.contains);

    if (isNegative) {
      return "The request is rejected securely, validation rules are enforced correctly, and no unintended backend state changes occur.";
    }

    return expected;
  }
}
