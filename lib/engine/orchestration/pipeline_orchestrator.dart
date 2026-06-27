import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/forensics/pipeline_observer.dart';
import 'package:qa_genie/engine/parsers/response_classifier.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/engine/forensics/error_capture_utils.dart';
import 'package:qa_genie/engine/orchestration/stages/repair_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/parsing_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/fallback_stage.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/engine/orchestration/stages/validation_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/finalization_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/ai_generation_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/coverage_analysis_stage.dart';


class PipelineExecutionResult {
  final List<FinalizedTestCase> cases;
  final PipelineAuditReport auditReport;
  final String traceId;
  final String? hardErrorCode;
  PipelineExecutionResult({
    required this.cases,
    required this.auditReport,
    required this.traceId,
    this.hardErrorCode,
  });
}

class PipelineOrchestrator {
  final AiGenerationStage _aiGenerationStage;
  final ParsingStage _parsingStage;
  final RepairStage _repairStage;
  final ValidationStage _validationStage;
  final CoverageAnalysisStage _coverageAnalysisStage;
  final FallbackStage _fallbackStage;
  final FinalizationStage _finalizationStage;
  final ResponseClassifier _responseClassifier;

  const PipelineOrchestrator({
    required AiGenerationStage aiGenerationStage,
    required ParsingStage parsingStage,
    required RepairStage repairStage,
    required ValidationStage validationStage,
    required CoverageAnalysisStage coverageAnalysisStage,
    required FallbackStage fallbackStage,
    required FinalizationStage finalizationStage,
    ResponseClassifier responseClassifier = const ResponseClassifier(),
  }) : _aiGenerationStage = aiGenerationStage,
       _parsingStage = parsingStage,
       _repairStage = repairStage,
       _validationStage = validationStage,
       _coverageAnalysisStage = coverageAnalysisStage,
       _fallbackStage = fallbackStage,
       _finalizationStage = finalizationStage,
       _responseClassifier = responseClassifier;

  Future<PipelineExecutionResult> execute({
    required String prompt,
    required GenerationRequest request,
    void Function(String stage)? onStageChange,
  }) async {
    onStageChange?.call('analyzing');
    final aiResult = await _aiGenerationStage.execute(
      prompt: prompt,
      request: request,
    );

    debugPrint('PIPELINE: AI raw response length: ${aiResult.rawResponse.length}');
    final preview = aiResult.rawResponse.length > 50
        ? aiResult.rawResponse.substring(0, 50)
        : aiResult.rawResponse;
    debugPrint('PIPELINE: AI raw response preview: $preview');
    debugPrint('PIPELINE: AI transport failure: ${aiResult.hasTransportError}');
    debugPrint('PIPELINE: AI status code: ${aiResult.statusCode}');

    PipelineForensics.instance.onTraceEvent(
      '\n[SECTION 5 — PARSER ENTRY]\nPARSER_INPUT_LENGTH=${aiResult.rawResponse.length}',
    );
    PipelineForensics.instance.onTraceEvent(
      'PARSER_INPUT_FIRST_1000=${aiResult.rawResponse.length > 1000 ? aiResult.rawResponse.substring(0, 1000) : aiResult.rawResponse}',
    );

    onStageChange?.call('generating');

    final parsingResult = _parsingStage.execute(
      rawResponse: aiResult.rawResponse,
    );
    PipelineForensics.instance.onTraceEvent(
      '\n[SECTION 6 — PARSER OUTPUT]\nparsedCasesCount=${parsingResult.parsedCases.length}',
    );
    if (parsingResult.parsedCases.isEmpty) {
      PipelineForensics.instance.onTraceEvent('salvagerInvoked=true');
      PipelineForensics.instance.onTraceEvent('salvagerRecoveredCount=0');
    }
    for (final err in parsingResult.parserErrors) {
      PipelineForensics.instance.onTraceEvent('PARSER_ERROR: $err');
    }

    final aiReturnedCount = parsingResult.parsedCases.length;
    final aiWorkingCases = _hydrateParsedCases(
      parsingResult.parsedCases,
      request,
    );
    final repairResult = _repairStage.execute(
      cases: aiWorkingCases,
      targetCount: request.requestedCaseCount,
    );

    PipelineForensics.instance.onTraceEvent(
      '\n[SECTION 7 — REPAIR OUTPUT]\nrepairInputCount=${aiWorkingCases.length}',
    );
    PipelineForensics.instance.onTraceEvent(
      'repairOutputCount=${repairResult.cases.length}',
    );

    onStageChange?.call('validating');
    final validationResult = _validationStage.execute(
      cases: repairResult.cases,
      constraints: request.constraints,
    );
    final structuralRejected = validationResult.structuralRejectedCount;
    PipelineForensics.instance.onTraceEvent(
      '\n[SECTION 8 — VALIDATION OUTPUT]\nstructuralValidCount=${repairResult.cases.length - structuralRejected}',
    );
    PipelineForensics.instance.onTraceEvent(
      'semanticValidCount=${repairResult.cases.length - structuralRejected - validationResult.semanticRejectedCount}',
    );

    final acceptedAiCases = validationResult.validCases;
    final rejectedCount = validationResult.rejectedCount;

    final effectiveHardError = aiResult.hardErrorCode ??
        ((acceptedAiCases.isEmpty && aiResult.hasTransportError)
            ? 'SERVICE_UNAVAILABLE'
            : null);

    if (effectiveHardError != null) {
      if (aiResult.hardErrorCode == null) {
        debugPrint('PIPELINE: Transport error with no valid cases — hard error SERVICE_UNAVAILABLE');
      } else {
        debugPrint('PIPELINE: Hard error ${aiResult.hardErrorCode} — skipping fallback');
      }
      final auditReport = PipelineAuditReport(
        traceId: request.traceId,
        rejectedCases: validationResult.rejectedCases,
        repairLog: repairResult.repairLog,
        diversityBalance: const {},
        averageConfidence: 0,
        fallbackTriggers: const [],
        totalInputCases: aiReturnedCount,
        finalizedCases: 0,
        repairedCases: repairResult.repairedCount,
        rejectedCount: validationResult.rejectedCount,
        missingIntentIds: const [],
        prompt: prompt,
        rawAiResponse: aiResult.rawResponse,
        aiLatencyMs: aiResult.latencyMs,
        aiStatusCode: aiResult.statusCode,
        aiReturnedCount: aiReturnedCount,
        aiAcceptedCount: acceptedAiCases.length,
        structuralRejectedCount: validationResult.structuralRejectedCount,
        semanticRejectedCount: validationResult.semanticRejectedCount,
        realismRejectedCount: validationResult.realismRejectedCount,
        exportSafetyRejectedCount: validationResult.exportSafetyRejectedCount,
        repairedCount: repairResult.repairedCount,
        fallbackCount: 0,
        aiModelName: aiResult.modelName,
        aiApiUrl: aiResult.apiUrl,
        aiHttpStatusCode: aiResult.statusCode,
        aiErrorDetails: aiResult.errorDetails,
        aiErrorMessage: aiResult.errorMessage,
        cloudFunctionName: 'generate',
        cloudFunctionRegion: 'us-central1',
        networkErrorType: aiResult.hasTransportError
            ? ErrorCaptureUtils.extractNetworkErrorType(aiResult.errorMessage)
            : null,
        totalRetriesAttempted: aiResult.totalRetries,
        wasResponseMalformed: parsingResult.malformed,
        parserErrorMessages: parsingResult.parserErrors,
      );
      return PipelineExecutionResult(
        cases: const [],
        auditReport: auditReport,
        traceId: request.traceId,
        hardErrorCode: effectiveHardError,
      );
    }

    if (rejectedCount > 0) {
      unawaited(FunctionsService.recordValidatorRejected(rejectedCount));
    }

    // aiFailures tracked server-side in generate() catch block

    final outcomeType = _responseClassifier.classify(
      rawResponse: aiResult.rawResponse,
      validCaseCount: acceptedAiCases.length,
      targetCaseCount: request.requestedCaseCount,
      malformed: parsingResult.malformed,
      transportFailure: aiResult.hasTransportError,
      statusCode: aiResult.statusCode,
    );

    final coverage = _coverageAnalysisStage.execute(
      request: request,
      acceptedCases: acceptedAiCases,
    );
    PipelineForensics.instance.onTraceEvent(
      '\n[SECTION 9 — COVERAGE OUTPUT]\nrequiredCount=${request.requestedCaseCount}',
    );
    PipelineForensics.instance.onTraceEvent(
      'acceptedCount=${acceptedAiCases.length}',
    );
    PipelineForensics.instance.onTraceEvent(
      'missingCount=${coverage.missingCount}',
    );

    // Fallback fills ALL missing cases — both full and partial rejections
    List<WorkingCase> finalWorkingCases;
    int fallbackCount = 0;
    if (coverage.needsFallback) {
      final fallbackCases = await _fallbackStage.fillMissing(
        request: request,
        existing: acceptedAiCases,
        coverage: coverage,
      );
      fallbackCount = fallbackCases.length;
      PipelineForensics.instance.onTraceEvent(
        '\n[SECTION 10 — FALLBACK OUTPUT]\nfallbackGeneratedCount=$fallbackCount',
      );
      finalWorkingCases = [
        ...acceptedAiCases,
        ...fallbackCases,
      ].take(request.requestedCaseCount).toList();
    } else {
      finalWorkingCases = acceptedAiCases;
    }

    onStageChange?.call('polishing');
    final finalized = _finalizationStage.execute(
      cases: finalWorkingCases,
      module: request.module,
    );

    PipelineForensics.instance.onTraceEvent(
      '\n[SECTION 11 — FINAL OUTPUT]\naiAcceptedCount=${acceptedAiCases.length}',
    );
    PipelineForensics.instance.onTraceEvent(
      'fallbackAcceptedCount=$fallbackCount',
    );
    PipelineForensics.instance.onTraceEvent(
      'finalCaseCount=${finalized.length}',
    );
    for (final tc in finalized) {
      PipelineForensics.instance.onTraceEvent(
        '\n[FINAL CASE]\ntitle=${tc.title}\nsource=${tc.source.name}',
      );
    }

    // Extract structured metadata if available
    final structured = aiResult.structuredResponse;
    final metadata = structured?['metadata'] as Map<String, dynamic>?;
    final error = structured?['error'] as Map<String, dynamic>?;
    final usage = structured?['data']?['usage'] as Map<String, dynamic>?;

    final auditReport = PipelineAuditReport(
      traceId: request.traceId,
      rejectedCases: validationResult.rejectedCases,
      repairLog: repairResult.repairLog,
      diversityBalance: _diversityBalance(finalWorkingCases),
      averageConfidence: _averageConfidence(finalWorkingCases),
      fallbackTriggers: _fallbackTriggers(
        outcomeType: outcomeType.name,
        coverage: coverage,
      ),
      totalInputCases: aiReturnedCount,
      finalizedCases: finalized.length,
      repairedCases: repairResult.repairedCount,
      rejectedCount: validationResult.rejectedCount,
      missingIntentIds: coverage.missingOutcomes,
      prompt: prompt,
      rawAiResponse: aiResult.rawResponse,
      aiLatencyMs: aiResult.latencyMs,
      aiStatusCode: aiResult.statusCode,
      aiReturnedCount: aiReturnedCount,
      aiAcceptedCount: acceptedAiCases.length,
      structuralRejectedCount: validationResult.structuralRejectedCount,
      semanticRejectedCount: validationResult.semanticRejectedCount,
      realismRejectedCount: validationResult.realismRejectedCount,
      exportSafetyRejectedCount: validationResult.exportSafetyRejectedCount,
      repairedCount: repairResult.repairedCount,
      fallbackCount: fallbackCount,
      cloudRequestId: metadata?['requestId'],
      cloudFunctionVersion: metadata?['functionVersion'],
      cloudLatencyMs: metadata?['latencyMs'],
      aiPromptTokens: usage?['promptTokens'],
      aiCompletionTokens: usage?['completionTokens'],
      aiTotalTokens: usage?['totalTokens'],
      aiErrorCode: error?['code'],
      aiErrorMessage: error?['message'],
      // New fields
      aiModelName: aiResult.modelName,
      aiApiUrl: aiResult.apiUrl,
      aiHttpStatusCode: aiResult.statusCode,
      aiErrorDetails: aiResult.errorDetails,
      cloudFunctionName: 'generate',
      cloudFunctionRegion: 'us-central1',
      networkErrorType: aiResult.hasTransportError
          ? ErrorCaptureUtils.extractNetworkErrorType(aiResult.errorMessage)
          : null,
      totalRetriesAttempted: aiResult.totalRetries,
      wasResponseMalformed: parsingResult.malformed,
      parserErrorMessages: parsingResult.parserErrors,
    );

    return PipelineExecutionResult(
      cases: finalized,
      auditReport: auditReport,
      traceId: request.traceId,
    );
  }

  List<WorkingCase> _hydrateParsedCases(
    List<Map<String, dynamic>> parsedCases,
    GenerationRequest request,
  ) {
    final hydratedCases = <WorkingCase>[];
    for (int i = 0; i < parsedCases.length; i++) {
      final plan = i < request.plan.length
          ? request.plan[i]
          : const <String, dynamic>{};
      final raw = Map<String, dynamic>.from(parsedCases[i]);
      final category = _normalizeCategory(
        _firstText(raw['categoryLock'], raw['category'], plan['category']),
      );
      raw['id'] = _firstText(raw['id'], _buildAiCaseId(request.module, i + 1));
      raw['module'] = _firstText(raw['module'], request.module);
      raw['feature'] = _firstText(raw['feature'], request.feature);
      raw['platform'] = _firstText(request.platform, raw['platform']);
      raw['priority'] = _firstText(raw['priority'], plan['priority'], 'Medium');
      raw['type'] = _firstText(
        raw['type'],
        plan['type'],
        category.toUpperCase(),
      );
      raw['categoryLock'] = category;
      raw['constraints'] = _firstText(raw['constraints'], request.constraints);
      raw['intent_id'] = _firstText(
        raw['intent_id'],
        raw['intentId'],
        plan['intent_id'],
        '__unknown__',
      );
      final workingCase = WorkingCase.fromJson(raw, traceId: request.traceId);

      // If testData is empty, extract from steps
      if (workingCase.testData.trim().isEmpty && workingCase.steps.isNotEmpty) {
        workingCase.testData = _extractTestDataFromSteps(workingCase.steps);
      }

      hydratedCases.add(workingCase);
    }
    return hydratedCases;
  }

  List<String> _fallbackTriggers({
    required String outcomeType,
    required CoverageAnalysisResult coverage,
  }) {
    if (!coverage.needsFallback) return const [];
    final mode = coverage.requiresFullFallback ? 'full' : 'partial';
    final outcomes = coverage.missingOutcomes.isEmpty
        ? 'no specific outcomes'
        : coverage.missingOutcomes.join(', ');
    return [
      '$mode fallback after $outcomeType: ${coverage.missingCount} missing cases ($outcomes)',
    ];
  }

  Map<String, int> _diversityBalance(List<WorkingCase> cases) {
    final balance = <String, int>{};
    for (final testCase in cases) {
      final profile = testCase.metadata.semanticProfile;
      balance[profile] = (balance[profile] ?? 0) + 1;
    }
    return balance;
  }

  double _averageConfidence(List<WorkingCase> cases) {
    if (cases.isEmpty) return 0;
    final total = cases.fold<double>(
      0,
      (sum, testCase) => sum + testCase.metadata.confidenceScore,
    );
    return total / cases.length;
  }

  String _buildAiCaseId(String module, int index) {
    final normalized = module
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();
    return 'AI_${normalized}_${index.toString().padLeft(3, '0')}';
  }

  String _firstText(
    Object? first, [
    Object? second,
    Object? third,
    Object? fourth,
  ]) {
    for (final value in [first, second, third, fourth]) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  String _normalizeCategory(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.contains('positive')) return 'positive';
    if (value.contains('negative')) return 'negative';
    if (value.contains('validation')) return 'validation';
    if (value.contains('boundary')) return 'boundary';
    if (value.contains('security')) return 'security';
    if (value.contains('session')) return 'session';
    return value.isEmpty ? 'positive' : value;
  }

  String _extractTestDataFromSteps(List<TestStep> steps) {
    final buffer = StringBuffer();
    for (final step in steps) {
      final data = step.data.trim();
      if (data.isNotEmpty) {
        // Only include data that looks like test input (email, password, etc.)
        if (data.contains('@') ||
            data.toLowerCase().contains('pass') ||
            data.contains('member') ||
            data.length > 3) {
          if (buffer.isNotEmpty) buffer.write('&');
          buffer.write(data);
        }
      }
    }
    return buffer.toString();
  }
}
