import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/validators/realism_validator.dart';
import 'package:qa_genie/engine/validators/semantic_validator.dart';
import 'package:qa_genie/engine/validators/structural_validator.dart';
import 'package:qa_genie/engine/validators/export_safety_validator.dart';

class ValidationStage {
  final StructuralValidator _structuralValidator;
  final SemanticValidator _semanticValidator;
  final ExportSafetyValidator _exportSafetyValidator;

  ValidationStage({
    StructuralValidator structuralValidator = const StructuralValidator(),
    SemanticValidator? semanticValidator,
    ExportSafetyValidator exportSafetyValidator = const ExportSafetyValidator(),
  }) : _structuralValidator = structuralValidator,
       _semanticValidator = semanticValidator ?? SemanticValidator(),
       _exportSafetyValidator = exportSafetyValidator;

  ValidationStageResult execute({
    required List<WorkingCase> cases,
    String constraints = '', // receive constraints from orchestrator
  }) {
    final rejected = <RejectedCaseInfo>[];
    final structurallyValid = <WorkingCase>[];
    var structuralRejectedCount = 0;

    for (final testCase in cases) {
      final result = _structuralValidator.validateSingle(testCase);
      if (result.isValid) {
        structurallyValid.add(testCase);
      } else {
        structuralRejectedCount++;
        rejected.add(
          RejectedCaseInfo(
            title: testCase.title,
            reason: result.reason ?? 'Structural validation failed.',
            stage: 'StructuralValidation',
          ),
        );
      }
    }

    final semanticRejected = <RejectedCaseInfo>[];
    final semanticResult = _semanticValidator.validate(
      structurallyValid,
      semanticRejected.add,
    );
    rejected.addAll(semanticRejected);

    // Realism validation
    final realismValid = RealismValidator.validate(
      semanticResult.validCases,
      constraints,
      (info) => rejected.add(info),
    );

    final exportSafe = <WorkingCase>[];
    var exportSafetyRejectedCount = 0;
    for (final testCase in realismValid) {
      final result = _exportSafetyValidator.validate([testCase]);
      if (result.isSuccessful) {
        exportSafe.add(testCase);
      } else {
        exportSafetyRejectedCount++;
        rejected.add(
          RejectedCaseInfo(
            title: testCase.title,
            reason: result.errors.join('; '),
            stage: 'ExportSafetyValidation',
          ),
        );
      }
    }

    return ValidationStageResult(
      validCases: exportSafe,
      rejectedCases: rejected,
      structuralRejectedCount: structuralRejectedCount,
      semanticRejectedCount: semanticRejected.length,
      realismRejectedCount:
          semanticResult.validCases.length - realismValid.length,
      exportSafetyRejectedCount: exportSafetyRejectedCount,
    );
  }
}

class ValidationStageResult {
  final List<WorkingCase> validCases;
  final List<RejectedCaseInfo> rejectedCases;
  final int structuralRejectedCount;
  final int semanticRejectedCount;
  final int realismRejectedCount;
  final int exportSafetyRejectedCount;

  const ValidationStageResult({
    required this.validCases,
    required this.rejectedCases,
    required this.structuralRejectedCount,
    required this.semanticRejectedCount,
    required this.realismRejectedCount,
    required this.exportSafetyRejectedCount,
  });

  int get rejectedCount => rejectedCases.length;
}
