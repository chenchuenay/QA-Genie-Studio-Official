import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/orchestration/stages/validation_stage.dart';
import 'package:qa_genie/engine/validators/structural_validator.dart';
import 'package:qa_genie/engine/validators/semantic_validator.dart';
import 'package:qa_genie/engine/validators/export_safety_validator.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

class _PassStructuralValidator extends StructuralValidator {
  const _PassStructuralValidator();

  @override
  StructuralValidationResult validateSingle(WorkingCase tc) {
    return const StructuralValidationResult(isValid: true);
  }
}

class _FailStructuralValidator extends StructuralValidator {
  const _FailStructuralValidator();

  @override
  StructuralValidationResult validateSingle(WorkingCase tc) {
    return const StructuralValidationResult(isValid: false, reason: 'Mock fail');
  }
}

class _PassSemanticValidator extends SemanticValidator {
  @override
  SemanticValidationResult validate(
    List<WorkingCase> cases,
    Function(RejectedCaseInfo) logRejected,
  ) {
    final valid = cases.map((c) => c.copy()).toList();
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

WorkingCase makeValidCase({String id = 'TC_001'}) {
  return WorkingCase(
    id: id,
    title: 'A valid test case title for testing',
    module: 'Auth',
    feature: 'Login',
    platform: 'WEB',
    priority: 'High',
    type: 'POSITIVE',
    categoryLock: 'positive',
    preconditions: ['User is authenticated'],
    testData: 'email=test@test.com',
    steps: [TestStep(action: 'Enter email address', data: 'test@test.com', expected: 'Email is accepted and validated')],
    expectedResult: 'User is authenticated successfully and redirected to dashboard',
    actualResult: '',
    status: '',
    metadata: CaseMetadata(source: CaseSource.ai, traceId: 'trace-1'),
    intentId: '',
  );
}

void main() {
  group('ValidationStage', () {
    test('execute returns valid cases when all validators pass', () {
      final stage = ValidationStage(
        structuralValidator: const _PassStructuralValidator(),
        semanticValidator: _PassSemanticValidator(),
        exportSafetyValidator: const _PassExportValidator(),
      );
      final cases = [makeValidCase()];
      final result = stage.execute(cases: cases);
      expect(result.validCases.length, equals(1));
      expect(result.rejectedCount, equals(0));
    });

    test('execute rejects structurally invalid cases', () {
      final stage = ValidationStage(
        structuralValidator: const _FailStructuralValidator(),
        semanticValidator: _PassSemanticValidator(),
        exportSafetyValidator: const _PassExportValidator(),
      );
      final cases = [makeValidCase()];
      final result = stage.execute(cases: cases);
      expect(result.validCases, isEmpty);
      expect(result.structuralRejectedCount, equals(1));
    });

    test('execute counts structural rejections correctly', () {
      final stage = ValidationStage(
        structuralValidator: const _FailStructuralValidator(),
        semanticValidator: _PassSemanticValidator(),
        exportSafetyValidator: const _PassExportValidator(),
      );
      final cases = [makeValidCase(), makeValidCase(id: 'TC_002')];
      final result = stage.execute(cases: cases);
      expect(result.structuralRejectedCount, equals(2));
    });

    test('execute returns rejected cases info', () {
      final stage = ValidationStage(
        structuralValidator: const _FailStructuralValidator(),
        semanticValidator: _PassSemanticValidator(),
        exportSafetyValidator: const _PassExportValidator(),
      );
      final cases = [makeValidCase()];
      final result = stage.execute(cases: cases);
      expect(result.rejectedCases.length, equals(1));
      expect(result.rejectedCases[0].stage, equals('StructuralValidation'));
    });

    test('execute handles empty input', () {
      final stage = ValidationStage(
        structuralValidator: const _PassStructuralValidator(),
        semanticValidator: _PassSemanticValidator(),
        exportSafetyValidator: const _PassExportValidator(),
      );
      final result = stage.execute(cases: []);
      expect(result.validCases, isEmpty);
      expect(result.rejectedCount, equals(0));
    });
  });
}
