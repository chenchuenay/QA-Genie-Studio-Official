import 'package:qa_genie/engine/recovery/repair_engine.dart';
import 'package:qa_genie/engine/parsers/schema_normalizer.dart';
import 'package:qa_genie/engine/parsers/ai_response_parser.dart';
import 'package:qa_genie/data/repositories/suite_repository.dart';
import 'package:qa_genie/engine/parsers/response_classifier.dart';
import 'package:qa_genie/engine/recovery/failure_classifier.dart';
import 'package:qa_genie/domain/usecases/save_suite_use_case.dart';
import 'package:qa_genie/domain/usecases/get_history_use_case.dart';
import 'package:qa_genie/engine/parsers/partial_case_extractor.dart';
import 'package:qa_genie/data/datasources/local/local_db_source.dart';
import 'package:qa_genie/engine/parsers/malformed_json_salvager.dart';
import 'package:qa_genie/engine/recovery/partial_suite_expander.dart';
import 'package:qa_genie/data/repositories/generation_repository.dart';
import 'package:qa_genie/engine/orchestration/stages/repair_stage.dart';
import 'package:qa_genie/data/datasources/remote/remote_api_source.dart';
import 'package:qa_genie/engine/orchestration/stages/parsing_stage.dart';
import 'package:qa_genie/engine/orchestration/pipeline_orchestrator.dart';
import 'package:qa_genie/engine/orchestration/stages/fallback_stage.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/domain/usecases/generate_test_cases_use_case.dart';
import 'package:qa_genie/engine/orchestration/stages/validation_stage.dart';
import 'package:qa_genie/engine/recovery/deterministic_case_generator.dart';
import 'package:qa_genie/engine/orchestration/policies/pipeline_policy.dart';
import 'package:qa_genie/engine/orchestration/stages/finalization_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/ai_generation_stage.dart';

class AppDependencies {
  AppDependencies._();

  static const LocalDbSource localDb = LocalDbSource();
  static const RemoteApiSource remoteApi = RemoteApiSource();
  static final FunctionsService functionsService = FunctionsService();

  static final SuiteRepository suiteRepository = SuiteRepository(
    local: localDb,
  );

  static final SaveSuiteUseCase saveSuiteUseCase = SaveSuiteUseCase(
    repository: suiteRepository,
  );

  static final GetHistoryUseCase getHistoryUseCase = GetHistoryUseCase(
    repository: suiteRepository,
  );

  static final GenerationRepository generationRepository = GenerationRepository(
    remote: remoteApi,
  );

  static final DeterministicCaseGenerator deterministicGenerator =
      DeterministicCaseGenerator();

  static final PipelineOrchestrator pipelineOrchestrator = PipelineOrchestrator(
    aiStage: AiGenerationStage(), // ✅ fixed: no constructor argument
    parsingStage: ParsingStage(
      parser: const AiResponseParser(),
      salvager: const MalformedJsonSalvager(),
      extractor: const PartialCaseExtractor(),
      normalizer: const SchemaNormalizer(),
    ),
    repairStage: RepairStage(
  repairEngine: const RepairEngine(),
),
    validationStage: ValidationStage(),
    fallbackStage: FallbackStage(
      generator: deterministicGenerator,
      expander: PartialSuiteExpander(
        deterministicGenerator: deterministicGenerator,
      ),
    ),
    finalizationStage: FinalizationStage(),
    responseClassifier: ResponseClassifier(),
    failureClassifier: FailureClassifier(),
    policy: PipelinePolicy(),
  );

  static final GenerateTestCasesUseCase generateTestCasesUseCase =
      GenerateTestCasesUseCase(orchestrator: pipelineOrchestrator);
}
