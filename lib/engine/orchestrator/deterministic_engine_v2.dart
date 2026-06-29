import '../ontology2/registry/domain_index.dart';
import '../ontology2/model/entity_def.dart';
import '../ontology2/model/action_def.dart';
import '../ontology2/model/domain_ontology.dart';
import '../ontology2/planners/ontology_scenario_planner.dart';
import '../ontology2/generators/ontology_title_generator.dart';
import '../ontology2/generators/ontology_step_generator.dart';
import '../ontology2/generators/ontology_precondition_generator.dart';
import '../ontology2/generators/ontology_data_generator.dart';
import '../ontology2/generators/ontology_expected_result_generator.dart';
import '../../domain/enums/case_source.dart';
import '../../domain/entities/test_step.dart';
import '../../domain/enums/generation_mode.dart';
import '../../domain/entities/finalized_test_case.dart';

class DeterministicEngineV2 {
  final String module;
  final String feature;
  final String platform;
  final String? constraints;
  final int targetCount;
  final GenerationMode mode;

  DeterministicEngineV2({
    required this.module,
    required this.feature,
    required this.platform,
    this.constraints,
    required this.targetCount,
    this.mode = GenerationMode.core,
  });

  Future<List<FinalizedTestCase>> generate() async {
    final ontologyDomain = DomainIndex.detect(module, feature);
    if (ontologyDomain == null) return [];

    final scenarioPlanner = OntologyScenarioPlanner(
      domain: ontologyDomain,
      targetCount: targetCount,
    );
    final scenarios = scenarioPlanner.plan();
    if (scenarios.isEmpty) return [];

    final testCases = <FinalizedTestCase>[];

    for (int i = 0; i < scenarios.length && testCases.length < targetCount; i++) {
      final os = scenarios[i];
      final entity = ontologyDomain.entity(os.entityId);
      final action = ontologyDomain.action(os.actionId);

      if (entity == null || action == null) continue;

      final title = OntologyTitleGenerator.generate(
        os.category, os.condition, os.isPositive, entity, action,
      );
      final preconditions = OntologyPreconditionGenerator.generate(
        os.category, os.condition, os.isPositive, entity, action, ontologyDomain,
        seed: i,
      );
      final testData = OntologyDataGenerator.generate(
        os.category, os.condition, os.isPositive, entity, action,
        platform: platform, seed: i,
      );
      final testDataStr = testData.entries.map((e) => '${e.key}=${e.value}').join(', ');
      final expectedResult = OntologyExpectedResultGenerator.generate(
        os.category, os.condition, os.isPositive, entity, action, platform,
      );

      final rawSteps = OntologyStepGenerator.generate(
        os.category, os.condition, os.isPositive, entity, action,
        ontologyDomain,
        platform: platform, seed: i,
      );

      final steps = rawSteps.map((s) => TestStep(
        action: s,
        data: '',
        expected: '',
      )).toList();

      final priority = _priorityFromCategory(os.category, os.actionId);
      final type = os.category.toUpperCase();

      testCases.add(
        FinalizedTestCase(
          id: 'TC_${module.replaceAll(' ', '')}_${(testCases.length + 1).toString().padLeft(3, '0')}',
          title: title,
          module: module,
          feature: feature,
          platform: platform,
          priority: priority,
          type: type,
          preconditions: preconditions,
          testData: testDataStr,
          steps: steps,
          expectedResult: expectedResult,
          actualResult: '',
          status: 'Not Executed',
          source: CaseSource.fallback,
        ),
      );
    }

    return testCases;
  }

  String _priorityFromCategory(String category, String actionId) {
    if (category == 'security' || category == 'session') return 'High';
    if (category == 'negative' || category == 'validation') return 'Medium';
    if (category == 'boundary') return 'Low';
    switch (actionId) {
      case 'login':
      case 'authenticate':
      case 'reset':
      case 'pay':
      case 'checkout':
      case 'transfer':
      case 'delete':
      case 'authorize':
        return 'High';
      case 'create':
      case 'view':
      case 'book':
      case 'trigger':
      case 'send':
        return 'Medium';
      default:
        return 'Low';
    }
  }
}
