import '../ontology/entities.dart';
import '../ontology/actions.dart';
import '../planners/domain_detector.dart';
import '../planners/coverage_planner.dart';
import '../planners/scenario_planner.dart';
import '../planners/constraint_parser.dart';
import '../generators/title_generator.dart';
import '../../domain/enums/case_source.dart';
import '../../domain/entities/test_step.dart';
import '../../domain/enums/generation_mode.dart';
import '../../domain/entities/finalized_test_case.dart';
import '../generators/flow_graph_generator.dart';
import '../generators/precondition_generator.dart';
import '../generators/expected_result_generator.dart';
import '../generators/data_generator.dart';

class DeterministicEngine {
  final String module;
  final String feature;
  final String platform;
  final String? constraints;
  final int targetCount;
  final GenerationMode mode;

  DeterministicEngine({
    required this.module,
    required this.feature,
    required this.platform,
    this.constraints,
    required this.targetCount,
    this.mode = GenerationMode.core,
  });

  Future<List<FinalizedTestCase>> generate() async {
    final domain = DomainDetector.detect(module, feature);
    final seedEntities = _detectSeedEntities(feature);
    if (seedEntities.isEmpty) return [];

    final parser = ConstraintParser(constraints ?? '');
    final constraintResult = parser.parse();

    final coveragePlanner = CoveragePlanner(
      totalCount: targetCount,
      mode: mode,
      constraints: constraints ?? '',
      seed: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
    );
    final coverageRequest = coveragePlanner.plan();

    final scenarioPlanner = ScenarioPlanner(
      domain: domain,
      categoryCounts: coverageRequest.categoryCounts,
      constraintKeywords: constraintResult.keywords,
      seedEntities: seedEntities,
      constraints: constraints ?? '',
    );
    final scenarios = scenarioPlanner.plan();

    final testCases = <FinalizedTestCase>[];
    for (int i = 0; i < scenarios.length && testCases.length < targetCount; i++) {
      final scenario = scenarios[i];
      final title = TitleGenerator.generate(scenario);

      final steps = FlowGraphGenerator.generate(
        domain.displayName,
        scenario.action.displayName,
        platform,
        constraints ?? '',
        condition: scenario.condition,
      )
          .map(
            (s) => TestStep(
              action: s['action']!,
              data: s['data']!,
              expected: s['expected']!,
            ),
          )
          .toList();

      final priority = _priorityFromCategory(scenario.category, scenario.action);
      final type = scenario.category.toUpperCase();

      final preconditions = PreconditionGenerator.generate(scenario, domain);
      final testData = DataGenerator.generate(scenario, constraints ?? '', platform: platform);
      final testDataStr = testData.entries.map((e) => '${e.key}=${e.value}').join(', ');
      final expectedResult = ExpectedResultGenerator.generate(scenario, domain, platform);

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

  EntityType _fallbackEntityForDomain(String domainId) {
    switch (domainId) {
      case 'identity':
        return EntityType.account;
      case 'commerce':
        return EntityType.item;
      case 'transaction':
        return EntityType.transaction;
      case 'scheduling':
        return EntityType.appointment;
      case 'records':
        return EntityType.record;
      case 'integration':
        return EntityType.request;
      default:
        return EntityType.item;
    }
  }

  String _priorityFromCategory(String category, ActionType action) {
    if (category == 'security' || category == 'session') return 'High';
    if (category == 'negative' || category == 'validation') return 'Medium';
    if (category == 'boundary') return 'Low';
    switch (action) {
      case ActionType.login:
      case ActionType.authenticate:
      case ActionType.reset:
      case ActionType.pay:
      case ActionType.checkout:
      case ActionType.transfer:
      case ActionType.delete:
      case ActionType.authorize:
        return 'High';
      case ActionType.create:
      case ActionType.view:
      case ActionType.book:
      case ActionType.trigger:
      case ActionType.send:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  Set<EntityType> _detectSeedEntities(String feature) {
    final f = feature.toLowerCase();
    if (f.contains('login') || f.contains('signin') || f.contains('auth'))
      return {EntityType.account, EntityType.credential};
    if (f.contains('reset') && f.contains('password'))
      return {EntityType.account, EntityType.resetToken};
    if (f.contains('refresh') || f.contains('session'))
      return {EntityType.session};
    if (f.contains('promo') || f.contains('coupon')) return {EntityType.coupon};
    if (f.contains('payment') || f.contains('checkout'))
      return {EntityType.payment};
    if (f.contains('cart') || f.contains('item'))
      return {EntityType.cart, EntityType.item};
    if (f.contains('transfer') || f.contains('wire'))
      return {EntityType.transfer, EntityType.balance};
    if (f.contains('beneficiary')) return {EntityType.beneficiary};
    if (f.contains('appointment') || f.contains('schedule'))
      return {EntityType.appointment, EntityType.provider};
    if (f.contains('prescription') || f.contains('refill'))
      return {EntityType.prescription};
    if (f.contains('lab') || f.contains('result'))
      return {EntityType.labResult};
    if (f.contains('telehealth') || f.contains('consultation'))
      return {EntityType.consultation, EntityType.webhook};

    final domain = DomainDetector.detect(module, feature);
    return {_fallbackEntityForDomain(domain.id)};
  }
}
