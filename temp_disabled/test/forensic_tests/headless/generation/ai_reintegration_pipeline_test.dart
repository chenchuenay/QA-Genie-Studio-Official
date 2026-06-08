import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/data/dto/generation_dto.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/engine/recovery/ai_repair_engine.dart';
import 'package:qa_genie/engine/parsers/ai_response_parser.dart';
import 'package:qa_genie/engine/recovery/partial_suite_expander.dart';
import 'package:qa_genie/engine/orchestration/stages/repair_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/parsing_stage.dart';
import 'package:qa_genie/engine/orchestration/pipeline_orchestrator.dart';
import 'package:qa_genie/engine/orchestration/stages/fallback_stage.dart';
import 'package:qa_genie/domain/usecases/generate_test_cases_use_case.dart';
import 'package:qa_genie/engine/orchestration/stages/validation_stage.dart';
import 'package:qa_genie/engine/recovery/deterministic_case_generator.dart';
import 'package:qa_genie/engine/orchestration/stages/finalization_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/ai_generation_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/coverage_analysis_stage.dart';

void main() {
  test(
    'AI partial suite is preserved and fallback fills only missing cases',
    () async {
      var aiCalled = false;
      AiGenerationStage.useTestCaller((prompt, _) async {
        aiCalled = true;
        expect(prompt, contains('Generate EXACTLY 16 testcases.'));
        return jsonEncode(_aiCases(12));
      });

      final generator = DeterministicCaseGenerator();
      final useCase = GenerateTestCasesUseCase(
        orchestrator: PipelineOrchestrator(
          aiGenerationStage: AiGenerationStage(),
          parsingStage: const ParsingStage(parser: AiResponseParser()),
          repairStage: const RepairStage(repairEngine: AiRepairEngine()),
          validationStage: ValidationStage(),
          coverageAnalysisStage: const CoverageAnalysisStage(),
          fallbackStage: FallbackStage(
            generator: generator,
            expander: PartialSuiteExpander(deterministicGenerator: generator),
          ),
          finalizationStage: FinalizationStage(),
        ),
      );

      final session = await useCase.execute(
        dto: const GenerationDto(
          module: 'login',
          feature: 'user login',
          platform: 'API',
          mode: GenerationMode.pro,
          count: 16,
          traceId: 'ai-reintegration-test',
        ),
      );

      final aiCount = session.testCases
          .where((testCase) => testCase.source == CaseSource.ai)
          .length;
      final fallbackCount = session.testCases
          .where((testCase) => testCase.source == CaseSource.fallback)
          .length;

      expect(aiCalled, isTrue);
      expect(session.count, 16);
      expect(aiCount, 12);
      expect(fallbackCount, 4);
      expect(session.auditReport.aiReturnedCount, 12);
      expect(session.auditReport.aiAcceptedCount, 12);
      expect(session.auditReport.fallbackCount, 4);
      expect(session.auditReport.finalizedCases, 16);
    },
  );
}

List<Map<String, dynamic>> _aiCases(int count) {
  return List.generate(count, (index) {
    final caseNumber = index + 1;
    final category = index < 11 ? 'positive' : 'negative';
    return {
      'id': 'AI_LOGIN_${caseNumber.toString().padLeft(3, '0')}',
      'title': 'AI authored login coverage case $caseNumber',
      'module': 'login',
      'feature': 'user login',
      'platform': 'API',
      'preconditions': ['API service is reachable'],
      'testData': 'email=user$caseNumber@example.com&password=ValidPass123!',
      'steps': [
        {
          'action': 'Send authentication request $caseNumber',
          'data': 'email=user$caseNumber@example.com',
          'expected': 'The API returns a structured authentication response',
        },
        {
          'action': 'Inspect authentication response $caseNumber',
          'data': '',
          'expected': 'The response body includes status and trace metadata',
        },
      ],
      'expectedResult':
          'The authentication endpoint returns a deterministic response with explicit status, trace metadata, and no unsafe implementation details.',
      'priority': 'High',
      'type': category.toUpperCase(),
      'categoryLock': category,
      'intent_id': 'ai_authored_case_$caseNumber',
    };
  });
}
