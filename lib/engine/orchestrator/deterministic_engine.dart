import '../ontology/entities.dart';
import '../ontology/actions.dart'; // Import to use ActionTypeExtension
import '../planners/domain_detector.dart';
import '../models/domain_context.dart';
import '../planners/coverage_planner.dart';
import '../planners/scenario_planner.dart';
import '../planners/constraint_parser.dart';
import '../generators/title_generator.dart';
import '../../domain/enums/case_source.dart';
import '../../domain/entities/test_step.dart';
import '../../domain/enums/generation_mode.dart';
import '../../domain/entities/finalized_test_case.dart';
import '../generators/flow_graph_generator.dart';

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
      final title = TitleGenerator.generate(scenario, feature);

      // Use the new FlowGraphGenerator
      final steps = FlowGraphGenerator.generate(
        DomainDetector.detect(module, feature).displayName, // Use displayName
        scenario.action.displayName,                        // Action
        platform,
        constraints ?? '',                                  // Pass constraints here
      )
          .map(
            (s) => TestStep(
              action: s['action']!,
              data: s['data']!,
              expected: s['expected']!,
            ),
          )
          .toList();

      final priority = _priorityFromCategory(scenario.category);
      final type = scenario.category.toUpperCase();

      final preconditions = _generatePreconditions(scenario.category, scenario.action, domain);
      final testData = _generateTestData(scenario.category, scenario.action, domain);
      final expectedResult = _generateExpectedResult(scenario.category);

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
          testData: testData,
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

  String _priorityFromCategory(String category) {
    switch (category) {
      case 'security':
      case 'session':
        return 'High';
      case 'negative':
      case 'validation':
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
    
    // Final fallback based on domain
    final domain = DomainDetector.detect(module, feature);
    return {_fallbackEntityForDomain(domain.id)};
  }

  List<String> _generatePreconditions(String category, ActionType action, DomainContext domain) {
    final base = [
      'User is authenticated with an active session and valid role',
      'User is on the $feature screen with all UI elements rendered',
      'Backend services are reachable and responding within normal latency',
    ];
    if (category == 'negative') {
      return [
        ...base,
        'Test environment has malformed or out-of-range input data ready',
        'No client-side validation bypasses are in place',
      ];
    }
    if (category == 'security') {
      return [
        ...base,
        'User has no special privileges (standard user role)',
        'XSS/CSRF payloads are prepared for injection points',
      ];
    }
    if (category == 'validation') {
      return [
        ...base,
        'Input fields accept a wide range of characters (alphanumeric, special, Unicode)',
        'Field length limits are known (e.g., max 255 chars for text inputs)',
      ];
    }
    if (category == 'boundary') {
      return [
        ...base,
        'System is configured with default maximum limits (no custom overrides)',
        'Data sets include values at min, max, just below max, and just above max',
      ];
    }
    if (category == 'session') {
      return [
        'User session has expired due to inactivity timeout',
        'User is redirected to login page without data loss',
      ];
    }
    return base;
  }

  String _generateTestData(String category, ActionType action, DomainContext domain) {
    if (category == 'negative') return 'Malformed payload: missing required fields, invalid email format, negative numbers';
    if (category == 'security') return 'Injection payload: <script>alert("xss")</script>; SQL: \' OR 1=1 --';
    if (category == 'validation') return 'Empty required fields, special chars (!@#\$%), exceeds max length (300 chars), Unicode injection';
    if (category == 'boundary') return 'Min=0, Max=9999999999, string length=256 chars, decimal with 6 places';
    if (category == 'session') return 'Expired JWT token, missing Authorization header, malformed Bearer token';
    if (category == 'positive') {
      if (domain.id == 'identity') return 'Valid credentials: admin@domain.com / SecurePass789!';
      if (domain.id == 'commerce') return 'Product SKU-7755 (in stock, \$49.99), quantity=2, valid coupon code SAVE10';
      if (domain.id == 'transaction') return 'From account: XXXX-8901 (balance \$5,000), to account: XXXX-3456, amount \$250.00';
      if (domain.id == 'scheduling') return 'Date range: 2026-08-01 to 2026-08-05, reason: Annual Leave, approver: manager@domain.com';
      if (domain.id == 'records') return 'Record ID: REC-0042, patient: John Doe, DOB: 1990-05-15';
      return 'Valid input data per $feature specification';
    }
    return 'Valid input data per $feature specification';
  }

  String _generateExpectedResult(String category) {
    switch (category) {
      case 'positive':
        return 'Operation completes successfully — system returns 200/OK with correct response payload';
      case 'negative':
        return 'System rejects the request with a clear error message; no data corruption occurs';
      case 'validation':
        return 'Inline validation errors appear for each invalid field; form does not submit';
      case 'security':
        return 'Malicious input is sanitized or rejected with 403/400; no XSS or SQL injection succeeds';
      case 'boundary':
        return 'System handles boundary values gracefully — no crash, no truncation, no silent overflow';
      case 'session':
        return 'API returns 401 Unauthorized; user is redirected to re-authentication flow';
      default:
        return 'Operation completes as expected with correct state transition';
    }
  }
}
