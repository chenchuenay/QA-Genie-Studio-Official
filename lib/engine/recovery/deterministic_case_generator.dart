import 'dart:math';
import 'package:qa_genie/core/utils/stable_hash.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/engine/planners/scenario_planner.dart';
import 'package:qa_genie/engine/forensics/trace_id_generator.dart';

class DeterministicCaseGenerator {
  DeterministicCaseGenerator();

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

  WorkingCase _buildCase({
    required int index,
    required String module,
    required String feature,
    required String platform,
    required String constraints,
    required Map<String, dynamic> skeleton,
  }) {
    final title = skeleton['title'] as String;
    final category = skeleton['category'] as String;
    final priority = skeleton['priority'] as String;
    final type = skeleton['type'] as String;

    // Generate realistic test data based on category and platform
    final testDataMap = _buildTestData(category, feature, platform);
    final testData = testDataMap.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('; ');

    // Generate preconditions (platform‑aware)
    final preconditions = _buildPreconditions(feature, platform, category);

    // Generate steps (platform‑aware)
    final steps = _buildSteps(feature, platform, category, testDataMap);

    // Generate expected result (platform‑aware)
    final expected = _buildExpectedResult(feature, platform, category);

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
      expectedResult: expected,
      actualResult: '',
      status: 'Not Executed',
      metadata: CaseMetadata(
        source: CaseSource.fallback,
        traceId: TraceIdGenerator.generate(),
        confidenceScore: 0.72,
        repairHistory: [],
        validationIssues: [],
      ),
    );
  }

  Map<String, dynamic> _buildTestData(
    String category,
    String feature,
    String platform,
  ) {
    final seed = StableHash.forText('$category|$feature|$platform', 999999);
    final random = Random(seed);

    switch (category) {
      case 'positive':
        return {
          'email': 'valid.user@example.com',
          'password': 'SecurePass123!',
        };
      case 'negative':
        return {
          'email': random.nextBool() ? '' : 'invalid-email',
          'password': random.nextBool() ? '123' : '',
        };
      case 'boundary':
        return {'email': 'a' * 250, 'password': 'P' * 500};
      case 'security':
        return {
          'email': "' OR 1=1 --",
          'password': '<script>alert(1)</script>',
        };
      case 'session':
        return {'token': 'expired_session_token'};
      default:
        return {'value': 'sample_input_${seed % 10000}'};
    }
  }

  List<String> _buildPreconditions(
    String feature,
    String platform,
    String category,
  ) {
    final preconditions = <String>[];
    if (platform == 'API') {
      preconditions.add('API service is reachable');
      preconditions.add('Authentication token is available');
    } else {
      preconditions.add('User is logged into the application');
      preconditions.add('Network connectivity is stable');
    }
    if (category == 'session') {
      preconditions.add('An active session exists');
    }
    if (category == 'security') {
      preconditions.add('Application has security headers enabled');
    }
    preconditions.add('$feature workflow is accessible');
    return preconditions;
  }

  List<TestStep> _buildSteps(
    String feature,
    String platform,
    String category,
    Map<String, dynamic> testData,
  ) {
    final steps = <TestStep>[];

    // Step 1: Navigate / open
    if (platform == 'API') {
      steps.add(
        TestStep(
          action: 'Send API request to $feature endpoint',
          data: testData.entries.map((e) => '${e.key}=${e.value}').join('&'),
          expected: 'HTTP 200 OK response received',
        ),
      );
    } else if (platform == 'Mobile') {
      steps.add(
        TestStep(
          action: 'Open the $feature screen',
          data: '',
          expected: 'Screen loads with all interactive elements',
        ),
      );
    } else {
      steps.add(
        TestStep(
          action: 'Navigate to the $feature page',
          data: '',
          expected: 'Page loads without errors',
        ),
      );
    }

    // Step 2: Primary action (with test data)
    if (platform == 'API') {
      steps.add(
        TestStep(
          action: 'Execute the primary operation',
          data: 'Payload: ${testData.toString()}',
          expected: 'API processes the request and returns structured data',
        ),
      );
    } else {
      steps.add(
        TestStep(
          action: 'Perform $feature action',
          data: testData.entries.map((e) => '${e.key}: ${e.value}').join(', '),
          expected: category == 'negative' || category == 'validation'
              ? 'Error message is displayed, action blocked'
              : 'Action completes successfully with visual confirmation',
        ),
      );
    }

    // Step 3: Verify outcome (category specific)
    if (category == 'security') {
      steps.add(
        TestStep(
          action: 'Inspect security headers and logs',
          data: '',
          expected:
              'No injection or XSS payload is executed; security headers present',
        ),
      );
    } else if (category == 'session') {
      steps.add(
        TestStep(
          action: 'Reload the application / refresh token',
          data: '',
          expected:
              'Session state is correctly restored or expired session is rejected',
        ),
      );
    } else {
      steps.add(
        TestStep(
          action: 'Verify final system state',
          data: '',
          expected:
              'Application state reflects the completed operation correctly',
        ),
      );
    }

    return steps;
  }

  String _buildExpectedResult(
    String feature,
    String platform,
    String category,
  ) {
    if (platform == 'API') {
      if (category == 'negative' || category == 'validation')
        return 'The API returns a 4xx client error with a clear error message and no state change.';
      if (category == 'security')
        return 'The API rejects the malicious payload and returns a 403 Forbidden status.';
      return 'The API returns a successful 2xx response with the expected resource representation.';
    }

    // Web / Mobile
    if (category == 'negative' || category == 'validation')
      return 'The application prevents the invalid action, shows an error message near the affected field, and maintains other user input.';
    if (category == 'security')
      return 'The input is sanitised, no script executes, and a security notification is shown if applicable.';
    if (category == 'session')
      return 'If session expired, user is redirected to login; otherwise session persists correctly across actions.';
    return 'The $feature workflow completes successfully, the user sees a confirmation, and the system updates appropriately.';
  }

  String _buildCaseId(String module, int index) {
    final normalized = module
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();
    return 'TC_${normalized}_${index.toString().padLeft(3, '0')}';
  }
}
