import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/models/generation_outcome.dart';
import 'package:qa_genie/engine/planners/scenario_planner.dart';
import 'package:qa_genie/engine/parsers/response_classifier.dart';
import 'package:qa_genie/engine/recovery/failure_classifier.dart';
import 'package:qa_genie/engine/forensics/trace_id_generator.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/engine/validators/structural_validator.dart';
import 'package:qa_genie/engine/orchestration/stages/repair_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/parsing_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/fallback_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/validation_stage.dart';
import 'package:qa_genie/engine/orchestration/policies/pipeline_policy.dart';
import 'package:qa_genie/engine/validators/coverage_contract_validator.dart';
import 'package:qa_genie/engine/orchestration/stages/finalization_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/ai_generation_stage.dart';

class PipelineOrchestrator {
  final AiGenerationStage _aiStage;
  final ParsingStage _parsingStage;
  final RepairStage _repairStage;
  final ValidationStage _validationStage;
  final FallbackStage _fallbackStage;
  final FinalizationStage _finalizationStage;
  final ResponseClassifier _responseClassifier;
  final StructuralValidator _structuralValidator = const StructuralValidator();

  const PipelineOrchestrator({
    required AiGenerationStage aiStage,
    required ParsingStage parsingStage,
    required RepairStage repairStage,
    required ValidationStage validationStage,
    required FallbackStage fallbackStage,
    required FinalizationStage finalizationStage,
    required ResponseClassifier responseClassifier,
    required FailureClassifier failureClassifier,
    required PipelinePolicy policy,
  }) : _aiStage = aiStage,
       _parsingStage = parsingStage,
       _repairStage = repairStage,
       _validationStage = validationStage,
       _fallbackStage = fallbackStage,
       _finalizationStage = finalizationStage,
       _responseClassifier = responseClassifier;

  Future<PipelineExecutionResult> execute({
    required String prompt,
    required GenerationRequest request,
  }) async {
    final traceId = TraceIdGenerator.generate();
    final plannedSkeletons = _getPlannedSkeletons(request);
    final requiredIntentIds = plannedSkeletons.map((sk) => sk['intent_id'] as String).toList();

    int retryAttempt = 0;
    const int maxRetries = 1;
    final expectedCount = request.requestedCaseCount;

    final aiResult = await _aiStage.execute(prompt: prompt);
    final parsing = _parsingStage.execute(rawResponse: aiResult.rawResponse);

    final validWorkingCases = <WorkingCase>[];
    final usedIntentIds = <String>{};

    for (final json in parsing.parsedCases) {
      final wc = WorkingCase.fromJson(json, traceId: traceId);
      final structural = _structuralValidator.validateSingle(wc);
      if (structural.isValid) {
        validWorkingCases.add(wc);
        usedIntentIds.add(wc.intentId);
      }
    }

    final outcomeType = _responseClassifier.classify(
      rawResponse: aiResult.rawResponse,
      validCaseCount: validWorkingCases.length,
      targetCaseCount: expectedCount,
      malformed: parsing.malformed,
      transportFailure: aiResult.hasTransportError,
      statusCode: aiResult.statusCode,
    );

    var outcome = GenerationOutcome(
      type: outcomeType,
      validCaseCount: validWorkingCases.length,
      requestedCaseCount: expectedCount,
      rawResponse: aiResult.rawResponse,
      statusCode: aiResult.statusCode,
      canRetry: (aiResult.statusCode == 429 || aiResult.statusCode == 503) && retryAttempt < maxRetries,
      recoveryMode: RecoveryMode.none,
      forensicReason: 'Initial classification',
    );

    // Fix #10: Check both category and intent coverage
    final categoryCoverageOk = CoverageContractValidator.satisfiesCategoryCoverage(
      validWorkingCases, plannedSkeletons);
    final intentCoverageOk = CoverageContractValidator.satisfiesIntentCoverage(
      validWorkingCases, plannedSkeletons);

    if ((!categoryCoverageOk || !intentCoverageOk) && outcome.type == GenerationOutcomeType.fullSuccess) {
      outcome = GenerationOutcome(
        type: GenerationOutcomeType.partialSuccess,
        validCaseCount: validWorkingCases.length,
        requestedCaseCount: expectedCount,
        rawResponse: aiResult.rawResponse,
        statusCode: aiResult.statusCode,
        canRetry: false,
        recoveryMode: RecoveryMode.partialExpansion,
        forensicReason: !categoryCoverageOk ? 'Category coverage not satisfied' : 'Intent coverage not satisfied',
      );
    }

    List<WorkingCase> workingCases;
    if (outcome.requiresFallback || outcome.type == GenerationOutcomeType.partialSuccess) {
      if (outcome.type == GenerationOutcomeType.partialSuccess) {
        final presentIntents = validWorkingCases.map((wc) => wc.intentId).toSet();
        final missing = requiredIntentIds.where((i) => !presentIntents.contains(i)).toList();
        workingCases = _fallbackStage.expandPartialSuite(
          request: request,
          existing: validWorkingCases,
          missingIntentIds: missing,
        );
      } else {
        workingCases = _fallbackStage.generateFullFallback(request: request, count: expectedCount);
      }
    } else {
      workingCases = validWorkingCases;
    }

    final repaired = _repairStage.execute(cases: workingCases, targetCount: expectedCount);
    final validated = _validationStage.execute(cases: repaired);
    final finalized = _finalizationStage.execute(cases: validated.validCases, module: request.module);

    final missing = requiredIntentIds.where((id) => !usedIntentIds.contains(id)).toList();
    final auditReport = PipelineAuditReport(
      traceId: traceId,
      rejectedCases: [],
      repairLog: [],
      diversityBalance: {},
      averageConfidence: 0.0,
      fallbackTriggers: [],
      totalInputCases: expectedCount,
      finalizedCases: finalized.length,
      repairedCases: repaired.length,
      rejectedCount: 0,
      missingIntentIds: missing,
      prompt: prompt,
      rawAiResponse: aiResult.rawResponse,
      aiLatencyMs: aiResult.latencyMs,
      aiModel: 'gemini-2.5-flash-lite',
      aiEndpoint: 'https://generativelanguage.googleapis.com/v1beta/...',
      aiStatusCode: aiResult.statusCode,
      aiReturnedCount: validWorkingCases.length,
      structuralRejectedCount: 0,
      semanticRejectedCount: 0,
      realismRejectedCount: 0,
      exportSafetyRejectedCount: 0,
      repairedCount: 0,
      fallbackCount: outcome.type == GenerationOutcomeType.partialSuccess ? 1 : 0,
    );

    return PipelineExecutionResult(cases: finalized, auditReport: auditReport, traceId: traceId);
  }

  List<Map<String, dynamic>> _getPlannedSkeletons(GenerationRequest request) {
    final planner = ScenarioPlanner(
      module: request.module,
      feature: request.feature,
      platform: request.platform,
      mode: GenerationMode.values.firstWhere(
        (e) => e.name == request.generationMode,
        orElse: () => GenerationMode.core,
      ),
      count: request.requestedCaseCount,
      domain: request.domain,
      constraints: request.constraints,
    );
    return planner.generateSkeletons();
  }
}

class PipelineExecutionResult {
  final List<FinalizedTestCase> cases;
  final PipelineAuditReport auditReport;
  final String traceId;
  const PipelineExecutionResult({required this.cases, required this.auditReport, required this.traceId});
}