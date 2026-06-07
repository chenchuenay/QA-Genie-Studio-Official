import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/engine/flows/generic_flow.dart';
import 'package:qa_genie/engine/title/title_composer.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/business/business_area.dart';
import 'package:qa_genie/engine/flows/scenario_expander.dart';
import 'package:qa_genie/engine/scenario/scenario_engine.dart';
import 'package:qa_genie/engine/expected_result/composer.dart';
import 'package:qa_genie/engine/adapters/platform_adapter.dart';
import 'package:qa_genie/engine/generators/data_generator.dart';
import 'package:qa_genie/engine/planners/coverage_planner.dart';
import 'package:qa_genie/engine/generators/banking_data_generator.dart';
import 'package:qa_genie/engine/generators/medical_data_generator.dart';
import 'package:qa_genie/engine/observations/observation_generator.dart';
import 'package:qa_genie/engine/generators/ecommerce_data_generator.dart';
import 'package:qa_genie/engine/generators/telehealth_data_generator.dart';

class DeterministicCaseGenerator {
  final Map<String, DataGenerator> _dataGenerators = {
    'authentication': AuthenticationDataGenerator(),
    'ecommerce': EcommerceDataGenerator(),
    'banking': BankingDataGenerator(),
    'medical': MedicalDataGenerator(),
    'telehealth': TelehealthDataGenerator(),
  };

  // ------------------------------------------------------------------
  // Public methods
  // ------------------------------------------------------------------

  List<WorkingCase> generate({
    required GenerationRequest request,
    required int count,
    int startIndex = 0,
  }) {
    final planner = CoveragePlanner(
      mode: _modeFromString(request.generationMode),
      totalCount: count,
      constraints: request.constraints,
      seed: request.traceId,
    );
    final coverage = planner.plan();

    final businessArea = _mapFeatureToBusinessArea(request.feature);

    final scenarioEngine = ScenarioEngine(request.traceId);
    final assignments = scenarioEngine.generateAssignments(
      categoryCounts: coverage.categoryCounts,
      businessArea: businessArea,
    );

    final cases = <WorkingCase>[];
    int idx = startIndex;
    for (final assignment in assignments) {
      idx++;
      cases.add(_buildCaseFromAssignment(assignment, request, idx));
    }
    return cases;
  }

  List<WorkingCase> generateByOutcomes({
    required GenerationRequest request,
    required List<String> outcomes,
    int startIndex = 0,
  }) {
    final businessArea = _mapFeatureToBusinessArea(request.feature);

    final cases = <WorkingCase>[];
    for (int i = 0; i < outcomes.length; i++) {
      final outcome = outcomes[i];
      final assignment = ScenarioAssignment(
        businessArea: businessArea,
        outcome: outcome,
        category: _categoryFromOutcome(outcome),
        risk: _riskFromOutcome(outcome),
      );
      cases.add(
        _buildCaseFromAssignment(assignment, request, startIndex + i + 1),
      );
    }
    return cases;
  }

  List<WorkingCase> generateByCategoryCounts({
    required GenerationRequest request,
    required Map<String, int> categoryCounts,
    int startIndex = 0,
  }) {
    final businessArea = _mapFeatureToBusinessArea(request.feature);
    final scenarioEngine = ScenarioEngine('${request.traceId}|$startIndex');
    final assignments = scenarioEngine.generateAssignments(
      categoryCounts: categoryCounts,
      businessArea: businessArea,
    );

    final cases = <WorkingCase>[];
    int idx = startIndex;
    for (final assignment in assignments) {
      idx++;
      cases.add(_buildCaseFromAssignment(assignment, request, idx));
    }
    return cases;
  }

  // ------------------------------------------------------------------
  // Core case builder
  // ------------------------------------------------------------------

  WorkingCase _buildCaseFromAssignment(
    ScenarioAssignment assignment,
    GenerationRequest request,
    int index,
  ) {
    final outcome = assignment.outcome;
    final category = assignment.category;
    final businessArea = assignment.businessArea;

    final genericFlow = _flowForBusinessArea(businessArea);
    final expandedNodes = ScenarioExpander.expand(genericFlow, outcome);

    final dataGen = _dataGenerators[businessArea.id];
    final testData = dataGen != null
        ? dataGen.generate(
            outcome: outcome,
            seed: '${request.traceId}|$outcome',
          )
        : <String, dynamic>{};

    final adapter = _adapterForPlatform(request.platform);
    final steps = adapter.toSteps(
      expandedNodes,
      testData,
      outcome: outcome,
      constraints: request.constraints,
    );

    // Collect scored observations
    final observations = <Map<String, dynamic>>[];
    for (final node in expandedNodes) {
      final obsList = ObservationGenerator.generate(
        outcome: outcome,
        entity: node.entity,
        platform: request.platform,
        businessArea: businessArea,
        module: request.module,
        feature: request.feature,
        constraints: request.constraints,
      );
      observations.addAll(obsList);
    }

    // Extract primary observation text (first observation's 'text' field)
    final primaryObservation = observations.isNotEmpty
        ? (observations.first['text'] as String?) ?? ''
        : '';

    final expectedResult = ExpectedResultComposer.compose(
      outcome: outcome,
      businessArea: businessArea,
      observations: observations,
      platform: request.platform,
      module: request.module,
      feature: request.feature,
      constraints: request.constraints,
    );

    final title = TitleComposer.compose(
      outcome: outcome,
      businessArea: businessArea,
      feature: request.feature,
      primaryObservation: primaryObservation,
    );

    final testDataString = testData.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final preconditions = _preconditionsFor(
      businessArea,
      outcome,
      request.platform,
    );

    return WorkingCase(
      id: _buildCaseId(request.module, index),
      title: title,
      module: request.module,
      feature: request.feature,
      platform: request.platform,
      priority: _priorityFromRisk(assignment.risk),
      type: category.toUpperCase(),
      categoryLock: category,
      constraints: request.constraints.isNotEmpty ? request.constraints : null,
      preconditions: preconditions,
      testData: testDataString,
      steps: steps,
      expectedResult: expectedResult,
      actualResult: '',
      status: 'Not Executed',
      metadata: CaseMetadata(
        source: CaseSource.fallback,
        traceId: request.traceId,
        confidenceScore: 0.85,
        repairHistory: [],
        validationIssues: [],
        intentId: outcome,
      ),
      intentId: outcome,
    );
  }

  // ------------------------------------------------------------------
  // Helper methods
  // ------------------------------------------------------------------

  GenerationMode _modeFromString(String mode) {
    return mode.toLowerCase() == 'pro'
        ? GenerationMode.pro
        : GenerationMode.core;
  }

  BusinessArea _mapFeatureToBusinessArea(String feature) {
    final lower = feature.toLowerCase();
    if (lower.contains('login') ||
        lower.contains('auth') ||
        lower.contains('password')) {
      return const BusinessArea(
        id: 'authentication',
        domain: 'security',
        riskProfile: 'MEDIUM',
      );
    }
    if (lower.contains('checkout') ||
        lower.contains('cart') ||
        lower.contains('order')) {
      return const BusinessArea(
        id: 'ecommerce',
        domain: 'transaction',
        riskProfile: 'HIGH',
      );
    }
    if (lower.contains('transfer') ||
        lower.contains('payment') ||
        lower.contains('otp')) {
      return const BusinessArea(
        id: 'banking',
        domain: 'finance',
        riskProfile: 'HIGH',
      );
    }
    return const BusinessArea(
      id: 'general',
      domain: 'general',
      riskProfile: 'LOW',
    );
  }

  GenericFlow _flowForBusinessArea(BusinessArea area) {
    switch (area.id) {
      case 'authentication':
        return GenericFlows.authentication;
      case 'ecommerce':
        return GenericFlows.transaction;
      case 'banking':
        return GenericFlows.transaction;
      default:
        return GenericFlows.authentication;
    }
  }

  PlatformAdapter _adapterForPlatform(String platform) {
    switch (platform.toUpperCase()) {
      case 'API':
        return ApiAdapter();
      case 'WEB':
        return WebAdapter();
      case 'MOBILE':
        return MobileAdapter();
      default:
        return ApiAdapter();
    }
  }

  List<String> _preconditionsFor(
    BusinessArea area,
    String outcome,
    String platform,
  ) {
    // BASELINE PRECONDITIONS (always present)
    final pre = <String>[];
    if (platform == 'API') {
      pre.add('API service is reachable');
      pre.add('Valid authentication token is available');
    } else {
      pre.add('Application is accessible and responsive');
      pre.add('Network connectivity is stable');
    }

    // OUTCOME‑SPECIFIC PRECONDITIONS
    if (area.id == 'authentication') {
      if (outcome == 'valid_login' ||
          outcome == 'social_login' ||
          outcome == 'mfa_login') {
        pre.add('User account exists with valid credentials');
      } else if (outcome == 'locked_account') {
        pre.add('User account is locked due to multiple failed attempts');
      } else if (outcome == 'nonexistent_user') {
        pre.add('User account does not exist in the system');
      }
      if (outcome == 'mfa_login') {
        pre.add('Multi‑factor authentication is enabled for the account');
      }
      if (outcome == 'social_login') {
        pre.add('Social login provider is properly configured');
      }
    } else if (area.id == 'ecommerce') {
      if (outcome == 'valid_checkout') {
        pre.add('Cart contains at least one item');
        pre.add('Valid payment method is saved or entered');
      } else if (outcome == 'insufficient_stock') {
        pre.add('Selected item has low inventory');
      }
      if (outcome.contains('coupon')) {
        pre.add('Coupon code is available');
      }
    } else if (area.id == 'banking') {
      if (outcome == 'valid_transfer') {
        pre.add('User has sufficient balance');
        pre.add('Beneficiary account is valid');
      } else if (outcome == 'insufficient_funds') {
        pre.add('User balance is less than transfer amount');
      }
    }
    return pre;
  }

  String _priorityFromRisk(String risk) {
    switch (risk) {
      case 'HIGH':
        return 'High';
      case 'MEDIUM':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  String _buildCaseId(String module, int index) {
    final normalized = module
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();
    return 'TC_${normalized}_${index.toString().padLeft(3, '0')}';
  }

  String _categoryFromOutcome(String outcome) {
    if (outcome.contains('invalid') || outcome.contains('fail'))
      return 'negative';
    if (outcome.contains('empty') || outcome.contains('validation'))
      return 'validation';
    if (outcome.contains('security') || outcome.contains('injection'))
      return 'security';
    if (outcome.contains('session') || outcome.contains('expiry'))
      return 'session';
    if (outcome.contains('boundary') || outcome.contains('length'))
      return 'boundary';
    return 'positive';
  }

  String _riskFromOutcome(String outcome) {
    if (outcome.contains('security') || outcome.contains('session'))
      return 'HIGH';
    if (outcome.contains('invalid') || outcome.contains('fail'))
      return 'MEDIUM';
    return 'LOW';
  }
}
