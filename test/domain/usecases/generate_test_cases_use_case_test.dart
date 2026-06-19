import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/data/dto/generation_dto.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/domain/usecases/generate_test_cases_use_case.dart';
import 'package:qa_genie/engine/orchestration/pipeline_orchestrator.dart';
import 'package:qa_genie/engine/orchestration/stages/ai_generation_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/parsing_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/repair_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/validation_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/coverage_analysis_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/fallback_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/finalization_stage.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/engine/parsers/ai_response_parser.dart';
import 'package:qa_genie/engine/recovery/ai_repair_engine.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';

void main() {
  group('GenerateTestCasesUseCase', () {
    test('execute with offline dev mode uses deterministic engine', () async {
      final useCase = GenerateTestCasesUseCase(
        orchestrator: PipelineOrchestrator(
          aiGenerationStage: AiGenerationStage(),
          parsingStage: ParsingStage(parser: _MockAiResponseParser()),
          repairStage: RepairStage(repairEngine: _MockAiRepairEngine()),
          validationStage: ValidationStage(),
          coverageAnalysisStage: CoverageAnalysisStage(),
          fallbackStage: FallbackStage(),
          finalizationStage: FinalizationStage(),
        ),
      );

      final dto = GenerationDto(
        module: 'Auth',
        feature: 'Login',
        platform: 'Web',
        mode: GenerationMode.core,
        count: 5,
        traceId: 'trace-gen-001',
      );

      final session = await useCase.execute(dto: dto);

      expect(session.traceId, 'trace-gen-001');
      expect(session.testCases.length, greaterThan(0));
      expect(session.testCases.first.source, CaseSource.fallback);
    });

    test('execute returns session with correct traceId', () async {
      final useCase = GenerateTestCasesUseCase(
        orchestrator: PipelineOrchestrator(
          aiGenerationStage: AiGenerationStage(),
          parsingStage: ParsingStage(parser: _MockAiResponseParser()),
          repairStage: RepairStage(repairEngine: _MockAiRepairEngine()),
          validationStage: ValidationStage(),
          coverageAnalysisStage: CoverageAnalysisStage(),
          fallbackStage: FallbackStage(),
          finalizationStage: FinalizationStage(),
        ),
      );

      final dto = GenerationDto(
        module: 'Payments',
        feature: 'Checkout',
        platform: 'iOS',
        mode: GenerationMode.core,
        count: 3,
        traceId: 'trace-gen-002',
      );

      final session = await useCase.execute(dto: dto);

      expect(session.traceId, 'trace-gen-002');
    });
  });
}

class _MockAiResponseParser extends AiResponseParser {
  _MockAiResponseParser() : super();

  @override
  ParsedAiResponse parse(String rawResponse) {
    return ParsedAiResponse(
      cases: [],
      salvaged: false,
      malformed: false,
    );
  }
}

class _MockAiRepairEngine extends AiRepairEngine {
  @override
  List<WorkingCase> repair(List<WorkingCase> cases, int targetCount) {
    return cases;
  }
}
