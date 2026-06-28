import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/orchestration/pipeline_orchestrator.dart';
import 'package:qa_genie/engine/orchestration/stages/ai_generation_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/parsing_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/repair_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/validation_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/coverage_analysis_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/fallback_stage.dart';
import 'package:qa_genie/engine/orchestration/stages/finalization_stage.dart';
import 'package:qa_genie/engine/parsers/response_classifier.dart';
import 'package:qa_genie/engine/parsers/ai_response_parser.dart';
import 'package:qa_genie/engine/recovery/ai_repair_engine.dart';
import 'package:qa_genie/engine/validators/structural_validator.dart';
import 'package:qa_genie/engine/validators/semantic_validator.dart';
import 'package:qa_genie/engine/validators/export_safety_validator.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'dart:convert';

class _MockParser extends AiResponseParser {
  final List<Map<String, dynamic>> cases;

  const _MockParser({required this.cases});

  @override
  ParsedAiResponse parse(String rawResponse) {
    return ParsedAiResponse(cases: cases, salvaged: false, malformed: false, parserErrors: []);
  }
}

class _NoOpRepairEngine extends AiRepairEngine {
  @override
  List<WorkingCase> repair(List<WorkingCase> cases, int targetCount) {
    return cases.map((c) => c.copy()).toList();
  }
}

class _PassStructuralValidator extends StructuralValidator {
  const _PassStructuralValidator();

  @override
  StructuralValidationResult validateSingle(WorkingCase tc) {
    return const StructuralValidationResult(isValid: true);
  }
}

class _PassSemanticValidator extends SemanticValidator {
  @override
  SemanticValidationResult validate(
    List<WorkingCase> cases,
    Function(RejectedCaseInfo) logRejected,
  ) {
    final valid = cases.map((c) => c.copy()).toList();
    for (final c in valid) {
      c.metadata.semanticProfile = 'functional';
      c.metadata.fingerprint = 'fp';
    }
    return SemanticValidationResult(validCases: valid, rejectedReasons: {});
  }
}

class _PassExportValidator extends ExportSafetyValidator {
  const _PassExportValidator();

  @override
  ExportSafetyResult validate(List<WorkingCase> cases) {
    return const ExportSafetyResult(true, []);
  }
}

Future<String> _successCaller(String prompt, GenerationRequest request) async {
  return jsonEncode({
    'success': true,
    'data': {'testCases': [{'id': 'TC_001', 'title': 'Test case', 'module': 'Auth', 'feature': 'Login', 'platform': 'WEB', 'type': 'POSITIVE', 'steps': [], 'expectedResult': 'Success', 'testData': '', 'preconditions': []}]},
    'metadata': {'model': 'test-model'},
  });
}

void main() {
  group('PipelineOrchestrator', () {
    test('execute returns PipelineExecutionResult with cases', () async {
      AiGenerationStage.useTestCaller(_successCaller);
      addTearDown(() => AiGenerationStage.useTestCaller(_successCaller));

      final parsingStage = ParsingStage(
        parser: const _MockParser(cases: [
          {'id': 'TC_001', 'title': 'Test case', 'module': 'Auth', 'feature': 'Login', 'platform': 'WEB', 'type': 'POSITIVE', 'steps': [], 'expectedResult': 'Success', 'testData': '', 'preconditions': []},
        ]),
      );

      final orchestrator = PipelineOrchestrator(
        aiGenerationStage: AiGenerationStage(),
        parsingStage: parsingStage,
        repairStage: RepairStage(repairEngine: _NoOpRepairEngine()),
        validationStage: ValidationStage(
          structuralValidator: const _PassStructuralValidator(),
          semanticValidator: _PassSemanticValidator(),
          exportSafetyValidator: const _PassExportValidator(),
        ),
        coverageAnalysisStage: const CoverageAnalysisStage(),
        fallbackStage: const FallbackStage(),
        finalizationStage: FinalizationStage(),
        responseClassifier: const ResponseClassifier(),
      );

      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 1,
        plan: [{'category': 'positive', 'intent_id': 'valid_login'}],
        traceId: 'trace-1',
      );
      final result = await orchestrator.execute(prompt: 'test prompt', request: request);
      expect(result, isA<PipelineExecutionResult>());
      expect(result.cases, isNotEmpty);
    });

    test('execute returns traceId in result', () async {
      AiGenerationStage.useTestCaller(_successCaller);
      addTearDown(() => AiGenerationStage.useTestCaller(_successCaller));

      final parsingStage = ParsingStage(
        parser: const _MockParser(cases: [
          {'id': 'TC_001', 'title': 'Test', 'module': 'Auth', 'feature': 'Login', 'platform': 'WEB', 'type': 'POSITIVE', 'steps': [], 'expectedResult': 'Success', 'testData': '', 'preconditions': []},
        ]),
      );

      final orchestrator = PipelineOrchestrator(
        aiGenerationStage: AiGenerationStage(),
        parsingStage: parsingStage,
        repairStage: RepairStage(repairEngine: _NoOpRepairEngine()),
        validationStage: ValidationStage(
          structuralValidator: const _PassStructuralValidator(),
          semanticValidator: _PassSemanticValidator(),
          exportSafetyValidator: const _PassExportValidator(),
        ),
        coverageAnalysisStage: const CoverageAnalysisStage(),
        fallbackStage: const FallbackStage(),
        finalizationStage: FinalizationStage(),
        responseClassifier: const ResponseClassifier(),
      );

      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 1,
        plan: [],
        traceId: 'test-trace',
      );
      final result = await orchestrator.execute(prompt: 'test', request: request);
      expect(result.traceId, equals('test-trace'));
    });

    test('PipelineExecutionResult constructor works', () {
      final auditReport = PipelineAuditReport(traceId: 'trace-1');
      final result = PipelineExecutionResult(
        cases: [],
        auditReport: auditReport,
        traceId: 'trace-1',
      );
      expect(result.cases, isEmpty);
      expect(result.traceId, equals('trace-1'));
      expect(result.hardErrorCode, isNull);
    });

    test('PipelineExecutionResult with hardErrorCode', () {
      final auditReport = PipelineAuditReport(traceId: 'trace-1');
      final result = PipelineExecutionResult(
        cases: [],
        auditReport: auditReport,
        traceId: 'trace-1',
        hardErrorCode: 'LIMIT_REACHED',
      );
      expect(result.hardErrorCode, equals('LIMIT_REACHED'));
    });
  });
}
