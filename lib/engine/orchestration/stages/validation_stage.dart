import 'package:qa_genie/engine/models/pipeline_models.dart';

class ValidationStage {
  const ValidationStage();

  ValidationStageResult execute({required List<WorkingCase> cases}) {
    // In Sprint 1, early structural validation already filtered bad cases.
    // All passed cases are valid.
    return ValidationStageResult(validCases: cases, rejectedCases: []);
  }
}

class ValidationStageResult {
  final List<WorkingCase> validCases;
  final List<WorkingCase> rejectedCases;
  const ValidationStageResult({required this.validCases, required this.rejectedCases});
}