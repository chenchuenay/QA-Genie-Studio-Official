import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/validators/realism_validator.dart';
import 'package:qa_genie/engine/validators/semantic_validator.dart';
import 'package:qa_genie/engine/validators/structural_validator.dart';
import 'package:qa_genie/engine/validators/contracts/pipeline_contract_validator.dart';

class ValidationStage {
  final StructuralValidator _structuralValidator;
  final SemanticValidator _semanticValidator;
  final RealismValidator _realismValidator;
  final PipelineContractValidator _contractValidator;

  const ValidationStage({
    required StructuralValidator structuralValidator,
    required SemanticValidator semanticValidator,
    required RealismValidator realismValidator,
    required PipelineContractValidator contractValidator,
  }) : _structuralValidator = structuralValidator,
       _semanticValidator = semanticValidator,
       _realismValidator = realismValidator,
       _contractValidator = contractValidator;

  ValidationStageResult execute({required List<WorkingCase> cases}) {
    final structResult = _structuralValidator.validate(cases, (rejected) {});
    final afterStructural = structResult.validCases;

    final semResult = _semanticValidator.validate(
      afterStructural,
      (rejected) {},
    );
    final afterSemantic = semResult.validCases;

    final validCases = <WorkingCase>[];
    final rejectedCases = <WorkingCase>[];

    for (final tc in afterSemantic) {
      final realismOk = _realismValidator.validate(tc); // now returns bool
      final contractOk = _contractValidator.validate(tc); // returns bool
      if (realismOk && contractOk) {
        validCases.add(tc);
      } else {
        rejectedCases.add(tc);
      }
    }

    return ValidationStageResult(
      validCases: validCases,
      rejectedCases: rejectedCases,
    );
  }
}

class ValidationStageResult {
  final List<WorkingCase> validCases;
  final List<WorkingCase> rejectedCases;
  const ValidationStageResult({
    required this.validCases,
    required this.rejectedCases,
  });
}
