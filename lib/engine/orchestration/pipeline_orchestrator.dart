import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/models/generation_outcome.dart';
import 'package:qa_genie/engine/parsers/response_classifier.dart';
import 'package:qa_genie/engine/recovery/failure_classifier.dart';
import 'package:qa_genie/engine/forensics/trace_id_generator.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/engine/forensics/models/pipeline_event.dart';
import 'package:qa_genie/engine/forensics/pipeline_audit_logger.dart';
import 'package:qa_genie/engine/orchestration/stages/repair_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/parsing_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/fallback_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/validation_stage.dart';
import 'package:qa_genie/engine/orchestration/policies/pipeline_policy.dart';
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
    final auditLogger = PipelineAuditLogger(traceId: traceId);

    int retryAttempt = 0;
    const int maxRetries = 1;
    final expectedCount = request.requestedCaseCount;

    GenerationOutcome outcome;

    while (true) {
      auditLogger.log(
        PipelineEvent(
          stage: 'ai_generation',
          action: 'started',
          beforeCount: 0,
          afterCount: 0,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          traceId: traceId,
          metadata: const {},
        ),
      );

      final aiResult = await _aiStage.execute(prompt: prompt);
      final parsing = _parsingStage.execute(rawResponse: aiResult.rawResponse);

      final outcomeType = _responseClassifier.classify(
        rawResponse: aiResult.rawResponse,
        validCaseCount: parsing.parsedCases.length,
        targetCaseCount: expectedCount,
        malformed: parsing.malformed,
        transportFailure: aiResult.hasTransportError,
        statusCode: aiResult.statusCode,
      );

      outcome = GenerationOutcome(
        type: outcomeType,
        validCaseCount: parsing.parsedCases.length,
        requestedCaseCount: expectedCount,
        rawResponse: aiResult.rawResponse,
        statusCode: aiResult.statusCode,
        canRetry:
            (aiResult.statusCode == 429 || aiResult.statusCode == 503) &&
            retryAttempt < maxRetries,
        recoveryMode: RecoveryMode.none,
        forensicReason: 'Initial classification',
      );

      auditLogger.log(
        PipelineEvent(
          stage: 'classification',
          action: outcome.type.name,
          beforeCount: 0,
          afterCount: parsing.parsedCases.length,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          traceId: traceId,
          metadata: {'reason': outcome.forensicReason},
        ),
      );

      if (outcome.canRetry) {
        retryAttempt++;
        auditLogger.log(
          PipelineEvent(
            stage: 'retry',
            action: 'retry_attempt_$retryAttempt',
            beforeCount: 0,
            afterCount: 0,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            traceId: traceId,
            metadata: {'reason': 'retry_triggered'},
          ),
        );
        continue;
      }

      // Proceed to processing
      List<WorkingCase> workingCases = parsing.parsedCases
          .map((json) => WorkingCase.fromJson(json, traceId: traceId))
          .toList();

      final aiReturnedCount = workingCases.length;

      if (outcome.requiresFallback ||
          outcome.type == GenerationOutcomeType.partialSuccess) {
        if (outcome.type == GenerationOutcomeType.partialSuccess) {
          workingCases = _fallbackStage.expandPartialSuite(
            request: request,
            existing: workingCases,
            targetCount: expectedCount,
          );
        } else {
          workingCases = _fallbackStage.generateFullFallback(
            request: request,
            count: expectedCount,
          );
        }
      }

      final fallbackCount =
          (outcome.type == GenerationOutcomeType.partialSuccess ||
              outcome.type == GenerationOutcomeType.emptyResponse ||
              outcome.type == GenerationOutcomeType.transportFailure ||
              outcome.type == GenerationOutcomeType.providerFailure)
          ? 1
          : 0;

      final repaired = _repairStage.execute(
        cases: workingCases,
        targetCount: expectedCount,
      );
      final repairedCount = repaired.length - workingCases.length;

      final validated = _validationStage.execute(cases: repaired);
      final finalized = _finalizationStage.execute(
        cases: validated.validCases,
        module: request.module,
      );

      // ------------------------------------------------------------------
      // Build the forensic‑enriched audit report
      // ------------------------------------------------------------------
      final baseReport = auditLogger.buildReport();

      final rejectedByStage = <String, int>{};
      for (final rejected in baseReport.rejectedCases) {
        rejectedByStage[rejected.stage] =
            (rejectedByStage[rejected.stage] ?? 0) + 1;
      }

      final aiLatency = aiResult.latencyMs;
      final aiStatusCode = aiResult.statusCode;

      final auditReport = PipelineAuditReport(
        // Copy all base fields
        traceId: traceId,
        rejectedCases: baseReport.rejectedCases,
        repairLog: baseReport.repairLog,
        diversityBalance: baseReport.diversityBalance,
        averageConfidence: baseReport.averageConfidence,
        fallbackTriggers: baseReport.fallbackTriggers,
        totalInputCases: expectedCount,
        finalizedCases: finalized.length,
        repairedCases: repaired.length,
        rejectedCount: baseReport.rejectedCount,
        // Forensic additions
        prompt: prompt,
        rawAiResponse: aiResult.rawResponse,
        aiLatencyMs: aiLatency,
        aiStatusCode: aiStatusCode,
        aiReturnedCount: aiReturnedCount,
        structuralRejectedCount: rejectedByStage['StructuralValidation'],
        semanticRejectedCount: rejectedByStage['SemanticValidation'],
        realismRejectedCount: rejectedByStage['RealismValidation'],
        exportSafetyRejectedCount: rejectedByStage['ExportSafetyValidation'],
        repairedCount: repairedCount,
        fallbackCount: fallbackCount,
        aiModel: 'gemini-2.5-flash-lite',
        aiEndpoint: 'https://generativelanguage.googleapis.com/v1beta/...',
      );

      return PipelineExecutionResult(
        cases: finalized,
        auditReport: auditReport,
        traceId: traceId,
      );
    }
  }
}

class PipelineExecutionResult {
  final List<FinalizedTestCase> cases;
  final PipelineAuditReport auditReport;
  final String traceId;

  const PipelineExecutionResult({
    required this.cases,
    required this.auditReport,
    required this.traceId,
  });
}
