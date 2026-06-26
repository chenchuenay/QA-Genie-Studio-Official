import 'package:qa_genie/data/dto/generation_dto.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/prompts/prompt_composer.dart';
import 'package:qa_genie/engine/planners/prompt_planner.dart';
import 'package:qa_genie/engine/forensics/pipeline_observer.dart';
import 'package:qa_genie/engine/orchestration/pipeline_orchestrator.dart';
import 'package:qa_genie/core/forensics/forensics_provider.dart';
import 'package:qa_genie/engine/forensics/error_capture_utils.dart';
import 'package:qa_genie/engine/orchestrator/deterministic_engine.dart';
import 'package:qa_genie/core/security/content_filter.dart';
import 'package:qa_genie/core/security/security_filter.dart';
import 'package:qa_genie/core/config/app_environment.dart';

class GenerateTestCasesUseCase {
  final PipelineOrchestrator _orchestrator;
  const GenerateTestCasesUseCase({required PipelineOrchestrator orchestrator})
    : _orchestrator = orchestrator;

  Future<GenerationSession> execute({
    required GenerationDto dto,
    void Function(String stage)? onStageChange,
  }) async {
    // ----- Try AI generation first -----
    try {
      onStageChange?.call('analyzing');
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

      final sanitized = SecurityFilter.sanitize(prompt);
      if (sanitized.blocked) {
        throw Exception('Prompt blocked by security filter: ${sanitized.findings.join(", ")}');
      }
      if (sanitized.hasFindings) {
        debugPrint('🔒 PII scrubbed: ${sanitized.findings.join(", ")}');
      }
      final safePrompt = sanitized.sanitized;

      PipelineForensics.instance.onTraceEvent(
        '[AI REQUEST]\ntraceId=${dto.traceId}',
      );
      PipelineForensics.instance.onTraceEvent('model=deepseek-v4-flash');
      PipelineForensics.instance.onTraceEvent('promptLength=${safePrompt.length}');
      PipelineForensics.instance.onTraceEvent(
        'promptPreview=${safePrompt.length > 500 ? safePrompt.substring(0, 500) : safePrompt}',
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
        deviceId: dto.deviceId,
      );
      final result = await _orchestrator.execute(
        prompt: safePrompt,
        request: request,
        onStageChange: onStageChange,
      );

      // Check for hard errors before any fallback can happen
      if (result.hardErrorCode != null) {
        if (result.hardErrorCode == 'LIMIT_REACHED' ||
            result.auditReport.aiHttpStatusCode == 403 || 
            result.auditReport.aiHttpStatusCode == 429) {
          final errorMessage = result.auditReport.aiErrorMessage ?? 'Daily limit reached.';
          int? resetTime;
          if (errorMessage.contains('|')) {
            final parts = errorMessage.split('|');
            resetTime = int.tryParse(parts[1]);
          }
          
          throw QuotaExceededException(
            errorMessage.split('|')[0],
            isRateLimit: result.auditReport.aiHttpStatusCode == 429,
            resetTimeMillis: resetTime,
          );
        }
        
        if (result.hardErrorCode == 'SERVICE_UNAVAILABLE') {
          final detail = result.auditReport.networkErrorType ?? result.auditReport.aiErrorMessage ?? '';
          throw Exception(
            'AI service unavailable${detail.isNotEmpty ? ': $detail' : ''}. Your quota has not been consumed.',
          );
        }
      }

      final session = GenerationSession(
        traceId: result.traceId,
        testCases: result.cases,
        auditReport: result.auditReport,
      );
      
      try {
        await ForensicsProvider.instance.saveSnapshot(
          session: session,
          auditReport: result.auditReport,
          rawAiResponse: result.auditReport.rawAiResponse ?? '',
        );
      } catch (e) {
        debugPrint('Forensics save failed (non-blocking): $e');
      }

      return session;
    } catch (e) {
      if (e is QuotaExceededException) {
        rethrow;
      }
      final errMsg = e.toString();
      if (errMsg.contains('AD_TOKEN_EXPIRED')) {
        throw Exception('Ad token expired. Please watch another ad.');
      }
      if (EnvironmentAuthority.isDev) {
        rethrow;
      }
      // ----- AI failed – fall back to deterministic engine (both prod and dev) -----
      debugPrint('AI generation failed, using deterministic engine: $e');
      
      onStageChange?.call('analyzing');
      onStageChange?.call('generating');

      final engine = DeterministicEngine(
        module: ContentFilter.sanitizeField(dto.module),
        feature: ContentFilter.sanitizeField(dto.feature),
        platform: dto.platform,
        constraints: ContentFilter.sanitizeField(dto.constraints),
        targetCount: dto.count,
        mode: dto.mode,
      );
      final testCases = await engine.generate();

      onStageChange?.call('validating');
      onStageChange?.call('polishing');

      // Populate rich audit report for forensics
      final auditReport = PipelineAuditReport(
        traceId: dto.traceId,
        totalInputCases: 0,
        finalizedCases: testCases.length,
        fallbackCount: testCases.length,
        aiErrorCode: 'FALLBACK_TRIGGERED',
        aiErrorMessage: e.toString(),
        networkErrorType: ErrorCaptureUtils.extractNetworkErrorType(e),
        aiHttpStatusCode: ErrorCaptureUtils.extractHttpStatusCode(e),
        prompt: 'N/A (Deterministic)',
        rawAiResponse: '',
        aiModelName: 'Deterministic',
        aiApiUrl: 'N/A',
        cloudFunctionName: 'generate',
        cloudFunctionRegion: 'us-central1',
      );

      final session = GenerationSession(
        traceId: dto.traceId,
        testCases: testCases,
        auditReport: auditReport,
      );

      try {
        await ForensicsProvider.instance.saveSnapshot(
          session: session,
          auditReport: auditReport,
          rawAiResponse: '',
        );
      } catch (e) {
        debugPrint('Forensics fallback save failed: $e');
      }
      
      return session;
    }
  }
}
