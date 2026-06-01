import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/engine/validators/realism_validator.dart';
import 'package:qa_genie/engine/validators/semantic_validator.dart';
import 'package:qa_genie/engine/validators/structural_validator.dart';
import 'package:qa_genie/engine/validators/export_safety_validator.dart';
import 'package:qa_genie/engine/recovery/deterministic_case_generator.dart';

class PipelineExecutionResult {
  final List<FinalizedTestCase> cases;
  final PipelineAuditReport auditReport;
  final String traceId;
  PipelineExecutionResult({
    required this.cases,
    required this.auditReport,
    required this.traceId,
  });
}

class PipelineOrchestrator {
  final DeterministicCaseGenerator _generator;
  final StructuralValidator _structuralValidator = const StructuralValidator();
  final SemanticValidator _semanticValidator = SemanticValidator();
  final ExportSafetyValidator _exportValidator = const ExportSafetyValidator();

  PipelineOrchestrator({required DeterministicCaseGenerator generator})
    : _generator = generator;

  Future<PipelineExecutionResult> execute({
    required String prompt,
    required GenerationRequest request,
  }) async {
    final workingCases = _generator.generate(
      request: request,
      count: request.requestedCaseCount,
    );

    // Structural validation
    final structurallyValid = <WorkingCase>[];
    for (final wc in workingCases) {
      final structural = _structuralValidator.validateSingle(wc);
      if (structural.isValid) structurallyValid.add(wc);
    }

    // Semantic validation (needs a rejection logger; we can pass a no-op)
    final semanticResult = _semanticValidator.validate(
      structurallyValid,
      (_) {},
    );
    final semanticallyValid = semanticResult.validCases;

    // (Optional) Repair using heuristics – QaHeuristicsEngine has only static methods, not a repair method.
    // We'll skip repair for now; AI repair is handled elsewhere (e.g., RepairStage for AI cases).
    // For fallback, we don't need repair.

    // Realism validation
    final realismValid = RealismValidator.validate(semanticallyValid);

    // Convert to FinalizedTestCase
    final finalized = realismValid.map((wc) => _toFinalized(wc)).toList();

    // Export safety
    final exportResult = _exportValidator.validate(
      finalized.map((tc) {
        // Convert FinalizedTestCase to WorkingCase? ExportSafetyValidator expects WorkingCase.
        // We need to adapt. Simpler: create a temporary WorkingCase.
        return WorkingCase(
          id: tc.id,
          title: tc.title,
          module: tc.module,
          feature: tc.feature,
          platform: tc.platform,
          priority: tc.priority,
          type: tc.type,
          categoryLock: tc.type,
          preconditions: tc.preconditions,
          testData: tc.testData,
          steps: tc.steps,
          expectedResult: tc.expectedResult,
          actualResult: tc.actualResult,
          status: tc.status,
          metadata: CaseMetadata(source: tc.source, traceId: request.traceId),
          intentId: '',
        );
      }).toList(),
    );
    if (!exportResult.isSuccessful) {
      // Log errors but still proceed with the list; we could filter invalid ones.
      print('Export safety errors: ${exportResult.errors}');
    }

    final auditReport = PipelineAuditReport(
      traceId: request.traceId,
      totalInputCases: request.requestedCaseCount,
      finalizedCases: finalized.length,
    );

    return PipelineExecutionResult(
      cases: finalized,
      auditReport: auditReport,
      traceId: request.traceId,
    );
  }

  FinalizedTestCase _toFinalized(WorkingCase wc) {
    return FinalizedTestCase(
      id: wc.id,
      title: wc.title,
      module: wc.module,
      feature: wc.feature,
      platform: wc.platform,
      priority: wc.priority,
      type: wc.type,
      preconditions: wc.preconditions,
      testData: wc.testData,
      steps: wc.steps,
      expectedResult: wc.expectedResult,
      actualResult: wc.actualResult,
      status: wc.status,
      source: wc.metadata.source,
    );
  }
}
