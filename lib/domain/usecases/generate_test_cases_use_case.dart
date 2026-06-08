import 'package:qa_genie/data/dto/generation_dto.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/prompts/prompt_composer.dart';
import 'package:qa_genie/engine/planners/prompt_planner.dart';
import 'package:qa_genie/engine/forensics/pipeline_observer.dart';
import 'package:qa_genie/engine/orchestration/pipeline_orchestrator.dart';
import 'package:qa_genie/features/forensics/diagnostics_persistence_service.dart';
import 'package:qa_genie/engine/orchestrator/deterministic_engine.dart'; // new engine

class GenerateTestCasesUseCase {
  final PipelineOrchestrator _orchestrator;
  const GenerateTestCasesUseCase({required PipelineOrchestrator orchestrator})
    : _orchestrator = orchestrator;

  Future<GenerationSession> execute({required GenerationDto dto}) async {
    // ----- Try AI generation first -----
    try {
      final planner = PromptPlanner(
        module: dto.module,
        feature: dto.feature,
        platform: dto.platform,
        mode: dto.mode,
        count: dto.count,
        domain: dto.domain,
        constraints: dto.constraints,
      );
      final skeletons = planner.generateSkeletons();
      final prompt = PromptComposer.compose(
        module: dto.module,
        feature: dto.feature,
        platform: dto.platform,
        skeletons: skeletons,
        constraints: dto.constraints,
        domain: dto.domain,
      );

      PipelineForensics.instance.onTraceEvent(
        '[AI REQUEST]\ntraceId=${dto.traceId}',
      );
      PipelineForensics.instance.onTraceEvent('model=gemini-2.5-flash-lite');
      PipelineForensics.instance.onTraceEvent('promptLength=${prompt.length}');
      PipelineForensics.instance.onTraceEvent(
        'promptPreview=${prompt.length > 500 ? prompt.substring(0, 500) : prompt}',
      );

      final request = GenerationRequest(
        module: dto.module,
        feature: dto.feature,
        platform: dto.platform,
        generationMode: dto.mode.name,
        requestedCaseCount: dto.count,
        constraints: dto.constraints,
        domain: dto.domain,
        plan: skeletons,
        traceId: dto.traceId,
        adToken: dto.adToken,
      );
      final result = await _orchestrator.execute(
        prompt: prompt,
        request: request,
      );
      final session = GenerationSession(
        traceId: result.traceId,
        testCases: result.cases,
        auditReport: result.auditReport,
      );
      await DiagnosticsPersistenceService.saveSnapshot(
        session: session,
        auditReport: result.auditReport,
        rawAiResponse: result.auditReport.rawAiResponse ?? '',
      );
      return session;
    } catch (e) {
      // ----- AI failed – fall back to deterministic engine -----
      debugPrint('AI generation failed, using deterministic engine: $e');
      final engine = DeterministicEngine(
        module: dto.module,
        feature: dto.feature,
        platform: dto.platform,
        constraints: dto.constraints,
        targetCount: dto.count,
      );
      final testCases = await engine.generate();

      // Create a minimal audit report (no AI involved)
      final auditReport = PipelineAuditReport(
        traceId: dto.traceId,
        totalInputCases: 0,
        finalizedCases: testCases.length,
        fallbackCount: testCases.length,
        // other fields use defaults (empty lists, nulls)
      );

      final session = GenerationSession(
        traceId: dto.traceId,
        testCases: testCases,
        auditReport: auditReport,
      );

      await DiagnosticsPersistenceService.saveSnapshot(
        session: session,
        auditReport: auditReport,
        rawAiResponse: '',
      );
      return session;
    }
  }
}
