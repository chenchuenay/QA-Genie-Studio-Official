import 'package:qa_genie/data/repositories/suite_repository.dart';
import 'package:qa_genie/domain/usecases/save_suite_use_case.dart';
import 'package:qa_genie/domain/usecases/get_history_use_case.dart';
import 'package:qa_genie/data/datasources/local/local_db_source.dart';
import 'package:qa_genie/engine/recovery/partial_suite_expander.dart';
import 'package:qa_genie/engine/orchestration/pipeline_orchestrator.dart';
import 'package:qa_genie/engine/orchestration/stages/ai_generation_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/coverage_analysis_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/fallback_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/finalization_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/parsing_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/repair_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/validation_stage.dart';
import 'package:qa_genie/engine/parsers/ai_response_parser.dart';
import 'package:qa_genie/engine/parsers/malformed_json_salvager.dart';
import 'package:qa_genie/engine/parsers/partial_case_extractor.dart';
import 'package:qa_genie/engine/parsers/schema_normalizer.dart';
import 'package:qa_genie/engine/recovery/ai_repair_engine.dart';
import 'package:qa_genie/engine/recovery/deterministic_case_generator.dart';
import 'package:qa_genie/domain/usecases/generate_test_cases_use_case.dart';

class AppDependencies {
  AppDependencies._();

  static const LocalDbSource localDb = LocalDbSource();

  static final SuiteRepository suiteRepository = SuiteRepository(
    local: localDb,
  );
  static final SaveSuiteUseCase saveSuiteUseCase = SaveSuiteUseCase(
    repository: suiteRepository,
  );
  static final GetHistoryUseCase getHistoryUseCase = GetHistoryUseCase(
    repository: suiteRepository,
  );

  static final DeterministicCaseGenerator deterministicGenerator =
      DeterministicCaseGenerator();

  static final PartialSuiteExpander partialSuiteExpander = PartialSuiteExpander(
    deterministicGenerator: deterministicGenerator,
  );

  static final FallbackStage fallbackStage = FallbackStage(
    generator: deterministicGenerator,
    expander: partialSuiteExpander,
  );

  static final AiGenerationStage aiGenerationStage = AiGenerationStage();
  static const AiResponseParser aiResponseParser = AiResponseParser();
  static const MalformedJsonSalvager malformedJsonSalvager =
      MalformedJsonSalvager();
  static const PartialCaseExtractor partialCaseExtractor =
      PartialCaseExtractor();
  static const SchemaNormalizer schemaNormalizer = SchemaNormalizer();
  static const AiRepairEngine aiRepairEngine = AiRepairEngine();
  static final ParsingStage parsingStage = ParsingStage(
    parser: aiResponseParser,
    salvager: malformedJsonSalvager,
    extractor: partialCaseExtractor,
    normalizer: schemaNormalizer,
  );
  static const RepairStage repairStage = RepairStage(
    repairEngine: aiRepairEngine,
  );
  static final ValidationStage validationStage = ValidationStage();
  static const CoverageAnalysisStage coverageAnalysisStage =
      CoverageAnalysisStage();
  static final FinalizationStage finalizationStage = FinalizationStage();

  static final PipelineOrchestrator pipelineOrchestrator = PipelineOrchestrator(
    aiGenerationStage: aiGenerationStage,
    parsingStage: parsingStage,
    repairStage: repairStage,
    validationStage: validationStage,
    coverageAnalysisStage: coverageAnalysisStage,
    fallbackStage: fallbackStage,
    finalizationStage: finalizationStage,
  );

  static final GenerateTestCasesUseCase generateTestCasesUseCase =
      GenerateTestCasesUseCase(orchestrator: pipelineOrchestrator);
}
