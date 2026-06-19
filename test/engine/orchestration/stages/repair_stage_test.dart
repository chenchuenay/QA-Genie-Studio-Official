import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/orchestration/stages/repair_stage.dart';
import 'package:qa_genie/engine/recovery/ai_repair_engine.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

class _MockRepairEngine extends AiRepairEngine {
  @override
  List<WorkingCase> repair(List<WorkingCase> cases, int targetCount) {
    for (final tc in cases) {
      if (tc.title.trim().isEmpty) {
        tc.title = 'Repaired title';
      }
      if (tc.expectedResult.trim().isEmpty) {
        tc.expectedResult = 'Repaired expected';
      }
    }
    return cases;
  }
}

WorkingCase makeCase({
  String id = 'TC_001',
  String title = 'Test case',
  String expectedResult = 'Expected result',
}) {
  return WorkingCase(
    id: id,
    title: title,
    module: 'Auth',
    feature: 'Login',
    platform: 'WEB',
    priority: 'High',
    type: 'POSITIVE',
    categoryLock: 'positive',
    preconditions: [],
    testData: '',
    steps: [TestStep(action: 'Enter email', data: '', expected: 'done')],
    expectedResult: expectedResult,
    actualResult: '',
    status: '',
    metadata: CaseMetadata(source: CaseSource.ai, traceId: 'trace-1'),
    intentId: '',
  );
}

void main() {
  group('RepairStage', () {
    test('execute returns cases from repair engine', () {
      final stage = RepairStage(repairEngine: _MockRepairEngine());
      final cases = [makeCase()];
      final result = stage.execute(cases: cases, targetCount: 5);
      expect(result.cases.length, equals(1));
    });

    test('execute generates repair log for changed title', () {
      final stage = RepairStage(repairEngine: _MockRepairEngine());
      final cases = [makeCase(title: '')];
      final result = stage.execute(cases: cases, targetCount: 1);
      expect(result.repairLog, isNotEmpty);
      expect(result.repairLog[0], contains('title'));
    });

    test('execute generates repair log for changed expectedResult', () {
      final stage = RepairStage(repairEngine: _MockRepairEngine());
      final cases = [makeCase(expectedResult: '')];
      final result = stage.execute(cases: cases, targetCount: 1);
      expect(result.repairLog, isNotEmpty);
      expect(result.repairLog[0], contains('expectedResult'));
    });

    test('repairLog is empty when no changes', () {
      final stage = RepairStage(repairEngine: _MockRepairEngine());
      final cases = [makeCase()];
      final result = stage.execute(cases: cases, targetCount: 1);
      expect(result.repairLog, isEmpty);
    });

    test('repairedCount returns number of repaired cases', () {
      final stage = RepairStage(repairEngine: _MockRepairEngine());
      final cases = [
        makeCase(title: ''),
        makeCase(title: 'Has title', expectedResult: ''),
        makeCase(title: 'Ok', expectedResult: 'Ok'),
      ];
      final result = stage.execute(cases: cases, targetCount: 3);
      expect(result.repairedCount, equals(2));
    });

    test('execute handles empty list', () {
      final stage = RepairStage(repairEngine: _MockRepairEngine());
      final result = stage.execute(cases: [], targetCount: 0);
      expect(result.cases, isEmpty);
      expect(result.repairLog, isEmpty);
      expect(result.repairedCount, equals(0));
    });
  });
}
