import 'dart:math';
import 'package:qa_genie/core/utils/stable_hash.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/engine/builders/step_builder.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/planners/scenario_planner.dart';
import 'package:qa_genie/engine/knowledge/intent_registry.dart';
import 'package:qa_genie/engine/forensics/trace_id_generator.dart';
import 'package:qa_genie/engine/builders/preconditions_builder.dart';
import 'package:qa_genie/engine/builders/expected_result_builder.dart';

class DeterministicCaseGenerator {
  final PreconditionsBuilder _preconditionsBuilder;
  final StepBuilder _stepBuilder;
  final ExpectedResultBuilder _expectedResultBuilder;

  DeterministicCaseGenerator({
    PreconditionsBuilder? preconditionsBuilder,
    StepBuilder? stepBuilder,
    ExpectedResultBuilder? expectedResultBuilder,
  }) : _preconditionsBuilder = preconditionsBuilder ?? PreconditionsBuilder(),
       _stepBuilder = stepBuilder ?? StepBuilder(),
       _expectedResultBuilder = expectedResultBuilder ?? ExpectedResultBuilder();

  List<WorkingCase> generate({
    required GenerationRequest request,
    required int count,
    int startIndex = 0,
  }) {
    final planner = ScenarioPlanner(
      module: request.module,
      feature: request.feature,
      platform: request.platform,
      mode: GenerationMode.values.firstWhere(
        (e) => e.name == request.generationMode,
        orElse: () => GenerationMode.core,
      ),
      count: count,
      domain: request.domain,
      constraints: request.constraints,
    );
    final skeletons = planner.generateSkeletons();
    final generated = <WorkingCase>[];
    for (int i = 0; i < skeletons.length; i++) {
      final skeleton = skeletons[i];
      generated.add(
        _buildCase(
          index: startIndex + i + 1,
          module: request.module,
          feature: request.feature,
          platform: request.platform,
          constraints: request.constraints,
          skeleton: skeleton,
        ),
      );
    }
    return generated;
  }

  List<WorkingCase> generateByIntentIds({
    required GenerationRequest request,
    required List<String> intentIds,
  }) {
    final generated = <WorkingCase>[];
    for (int i = 0; i < intentIds.length; i++) {
      final intentId = intentIds[i];
      final skeleton = {
        'intent_id': intentId,
        'category': _categoryFromIntent(intentId),
        'priority': 'Medium',
        'type': 'GENERAL',
        'business_area': _businessAreaFromIntent(intentId) ?? 'general',
      };
      generated.add(
        _buildCase(
          index: i + 1,
          module: request.module,
          feature: request.feature,
          platform: request.platform,
          constraints: request.constraints,
          skeleton: skeleton,
        ),
      );
    }
    return generated;
  }

  String _categoryFromIntent(String intentId) {
    if (intentId.contains('invalid') || intentId.contains('fail') || intentId.contains('credential')) return 'negative';
    if (intentId.contains('empty') || intentId.contains('validation')) return 'validation';
    if (intentId.contains('security') || intentId.contains('injection') || intentId.contains('sql')) return 'security';
    if (intentId.contains('session') || intentId.contains('expiry') || intentId.contains('timeout')) return 'session';
    if (intentId.contains('boundary') || intentId.contains('edge') || intentId.contains('length')) return 'boundary';
    return 'positive';
  }

  String? _businessAreaFromIntent(String intentId) {
    if (intentId.startsWith('auth_')) return 'authentication';
    if (intentId.startsWith('ecom_')) return 'ecommerce';
    if (intentId.startsWith('bank_')) return 'banking';
    return null;
  }

  WorkingCase _buildCase({
    required int index,
    required String module,
    required String feature,
    required String platform,
    required String constraints,
    required Map<String, dynamic> skeleton,
  }) {
    final intentId = skeleton['intent_id'] as String? ?? '__unknown__';
    final category = skeleton['category'] as String;
    final priority = skeleton['priority'] as String;
    final type = skeleton['type'] as String? ?? 'GENERAL';
    final businessArea = skeleton['business_area'] as String? ?? 'general';

    // Retrieve full intent from registry
    final intent = IntentRegistry.get(intentId);
    String title;
    Map<String, dynamic> testDataMap;
    String expectedResult;

    if (intent != null && !intentId.endsWith('_generic')) {
      // Use registry data for realistic generation
      title = intent.displayName;
      testDataMap = intent.sampleData;
      // Prefer intent's expectedOutcome, otherwise fallback to builder
      expectedResult = intent.expectedOutcome.isNotEmpty
          ? intent.expectedOutcome
          : _expectedResultBuilder.build(
              businessArea: businessArea,
              category: category,
              platform: platform,
            );
    } else {
      // Fallback for generic intents (should not happen if registry is loaded)
      title = _generateFallbackTitle(skeleton);
      testDataMap = _buildFallbackTestData(category, feature, platform, intentId);
      expectedResult = _expectedResultBuilder.build(
        businessArea: businessArea,
        category: category,
        platform: platform,
      );
    }

    final testData = testDataMap.entries.map((e) => '${e.key}=${e.value}').join('&');
    final preconditions = _preconditionsBuilder.build(
      feature: feature,
      platform: platform,
      category: category,
    );
    final steps = _stepBuilder.build(
      businessArea: businessArea,
      category: category,
      platform: platform,
      testData: testDataMap,
    );

    return WorkingCase(
      id: _buildCaseId(module, index),
      title: title,
      module: module,
      feature: feature,
      platform: platform,
      priority: priority,
      type: type,
      categoryLock: category,
      constraints: constraints.isNotEmpty ? constraints : null,
      preconditions: preconditions,
      testData: testData,
      steps: steps,
      expectedResult: expectedResult,
      actualResult: '',
      status: 'Not Executed',
      metadata: CaseMetadata(
        source: CaseSource.fallback,
        traceId: TraceIdGenerator.generate(),
        confidenceScore: 0.72,
        repairHistory: [],
        validationIssues: [],
        intentId: intentId,
      ),
      intentId: intentId,
    );
  }

  String _generateFallbackTitle(Map<String, dynamic> skeleton) {
    final intentId = skeleton['intent_id'] as String? ?? '';
    if (intentId == 'valid_authentication') return 'User logs in with valid credentials';
    if (intentId == 'invalid_credential') return 'Login fails with invalid password';
    if (intentId == 'empty_email') return 'Email field validation – empty input rejected';
    if (intentId == 'sql_injection') return 'SQL injection attempt blocked in login form';
    if (intentId == 'session_expiry') return 'Session expires after inactivity';
    return '${skeleton['category']} test case for ${skeleton['business_area']}';
  }

  Map<String, dynamic> _buildFallbackTestData(String category, String feature, String platform, String intentId) {
    final seed = StableHash.forText('$category|$feature|$platform|$intentId', 999999);
    final random = Random(seed);
    if (intentId.contains('valid_authentication')) {
      return {'email': 'valid.user@example.com', 'password': 'SecurePass123!'};
    }
    if (intentId.contains('invalid_credential')) {
      return {'email': 'user@example.com', 'password': 'wrongpassword'};
    }
    if (intentId.contains('empty_email')) {
      return {'email': '', 'password': 'anypass'};
    }
    if (intentId.contains('sql_injection')) {
      return {'email': "' OR 1=1 --", 'password': '<script>alert(1)</script>'};
    }
    if (intentId.contains('session_expiry')) {
      return {'token': 'expired_session_token'};
    }
    if (category == 'positive') {
      return {'email': 'valid.user@example.com', 'password': 'SecurePass123!'};
    }
    if (category == 'negative') {
      return {'email': random.nextBool() ? '' : 'invalid-email', 'password': random.nextBool() ? '123' : ''};
    }
    if (category == 'boundary') {
      return {'email': 'very long email (250+ chars)', 'password': 'very long password (500+ chars)'};
    }
    if (category == 'security') {
      return {'email': "' OR 1=1 --", 'password': '<script>alert(1)</script>'};
    }
    if (category == 'session') {
      return {'token': 'expired_session_token'};
    }
    return {'value': 'sample_input_${seed % 10000}'};
  }

  String _buildCaseId(String module, int index) {
    final normalized = module.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    return 'TC_${normalized}_${index.toString().padLeft(3, '0')}';
  }
}