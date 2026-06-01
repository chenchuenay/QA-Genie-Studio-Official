import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/planners/scenario_planner.dart';
import 'package:qa_genie/engine/forensics/trace_id_generator.dart';
import 'package:qa_genie/engine/builders/preconditions_builder.dart';
import 'package:qa_genie/engine/humanization/qa_heuristics_engine.dart';

class RepairEvent {
  final String testCaseId;
  final String changedField;
  final String before;
  final String after;
  final String reason;

  RepairEvent({
    required this.testCaseId,
    required this.changedField,
    required this.before,
    required this.after,
    required this.reason,
  });
}

class DeterministicRepair {
  final ScenarioPlanner planner;
  final String? traceId;
  final List<RepairEvent> repairEvents = [];

  DeterministicRepair({required this.planner, this.traceId});

  List<WorkingCase> repair(List<WorkingCase> cases, int targetCount) {
    final repaired = <WorkingCase>[];

    for (final tc in cases) {
      final oldExpected = tc.expectedResult;
      if (QaHeuristicsEngine.hasWeakExpectedResult(tc.expectedResult)) {
        tc.expectedResult = QaHeuristicsEngine.expectedResult(
          platform: tc.platform,
          category: tc.categoryLock.toLowerCase(),
          module: tc.module,
          feature: tc.feature,
          title: tc.title,
          domain: planner.domain,
        );
        repairEvents.add(
          RepairEvent(
            testCaseId: tc.id,
            changedField: 'expectedResult',
            before: oldExpected,
            after: tc.expectedResult,
            reason: 'weak_expected_result_rewrite',
          ),
        );
      }
      if (tc.preconditions.isEmpty) {
        tc.preconditions = PreconditionsBuilder.generic(tc.feature);
      }
      if (tc.steps.isEmpty) {
        tc.steps = _buildContextualSteps(tc.feature, tc.platform);
      }
      repaired.add(tc);
    }

    if (repaired.length >= targetCount) {
      return repaired.take(targetCount).toList();
    }

    final skeletons = planner.generateSkeletons();
    final existingTitles = repaired
        .map((e) => _normalizeTitle(e.title))
        .toSet();

    for (final sk in skeletons) {
      if (repaired.length >= targetCount) break;
      final title = sk['title'] as String;
      final normalized = _normalizeTitle(title);
      if (existingTitles.contains(normalized)) continue;
      existingTitles.add(normalized);

      final newCase = WorkingCase(
        id: _buildCaseId(sk['module'] as String, repaired.length + 1),
        title: title,
        module: sk['module'] as String,
        feature: sk['feature'] as String,
        platform: sk['platform'] as String,
        priority: sk['priority'] as String,
        type: sk['type'] as String,
        categoryLock: sk['category'] as String,
        constraints: '',
        preconditions: PreconditionsBuilder.generic(sk['feature'] as String),
        testData: '',
        steps: _buildContextualSteps(
          sk['feature'] as String,
          sk['platform'] as String,
        ),
        expectedResult: _buildExpectedResult(sk),
        actualResult: '',
        status: 'Not Executed',
        metadata: CaseMetadata(
          source: CaseSource.repaired,
          traceId: traceId ?? TraceIdGenerator.generate(),
          confidenceScore: 0.72,
          repairHistory: [],
          validationIssues: [],
        ),
      );
      repaired.add(newCase);
    }

    return repaired.take(targetCount).toList();
  }

  List<TestStep> _buildContextualSteps(String feature, String platform) {
    return [
      TestStep(
        action: 'Navigate to the $feature workflow',
        expected: 'The workflow loads successfully.',
      ),
      TestStep(
        action: 'Perform the primary $feature action',
        data: 'test@example.com',
        expected: 'The application processes the request.',
      ),
      TestStep(
        action: 'Verify final workflow state',
        expected: 'The final state reflects the completed operation.',
      ),
    ];
  }

  String _buildExpectedResult(Map<String, dynamic> sk) {
    return QaHeuristicsEngine.expectedResult(
      platform: sk['platform'] as String,
      category: (sk['category'] as String).toLowerCase(),
      module: sk['module'] as String,
      feature: sk['feature'] as String,
      title: sk['title'] as String,
      domain: planner.domain,
    );
  }

  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _buildCaseId(String module, int index) {
    final normalized = module
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();
    return 'TC_${normalized}_${index.toString().padLeft(3, '0')}';
  }
}