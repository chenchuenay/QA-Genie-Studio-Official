import 'package:qa_genie/data/repositories/suite_repository.dart';
import 'package:qa_genie/domain/usecases/save_suite_use_case.dart';
import 'package:qa_genie/domain/usecases/get_history_use_case.dart';
import 'package:qa_genie/data/datasources/local/local_db_source.dart';
import 'package:qa_genie/engine/recovery/partial_suite_expander.dart';
import 'package:qa_genie/data/datasources/remote/remote_api_source.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/engine/orchestration/pipeline_orchestrator.dart';
import 'package:qa_genie/engine/orchestration/stages/fallback_stage.dart';
import 'package:qa_genie/engine/recovery/deterministic_case_generator.dart';
import 'package:qa_genie/domain/usecases/generate_test_cases_use_case.dart';

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

  static final DeterministicCaseGenerator deterministicGenerator =
      DeterministicCaseGenerator();

  static final PartialSuiteExpander partialSuiteExpander = PartialSuiteExpander(
    deterministicGenerator: deterministicGenerator,
  );

  static final FallbackStage fallbackStage = FallbackStage(
    generator: deterministicGenerator,
    expander: partialSuiteExpander,
  );

  static final PipelineOrchestrator pipelineOrchestrator = PipelineOrchestrator(
    generator: deterministicGenerator,
  );

  static final GenerateTestCasesUseCase generateTestCasesUseCase =
      GenerateTestCasesUseCase(orchestrator: pipelineOrchestrator);
}
