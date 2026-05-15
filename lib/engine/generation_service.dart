import 'package:qa_genie/engine/platform_rules.dart';
import 'package:qa_genie/engine/generation_mode.dart';
import 'package:qa_genie/core/utils/stable_hash.dart';
import 'package:qa_genie/core/utils/id_generator.dart';
import 'package:qa_genie/engine/scenario_planner.dart';
import 'package:qa_genie/engine/generation_result.dart';
import 'package:qa_genie/core/utils/priority_utils.dart';
import 'package:qa_genie/engine/generation_metrics.dart';
import 'package:qa_genie/core/debug/pipeline_logger.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/engine/deterministic_repair.dart';
import 'package:qa_genie/engine/qa_heuristics_engine.dart';
import 'package:qa_genie/core/utils/test_data_factory.dart';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';
import 'package:qa_genie/engine/fallback/fallback_generator.dart';
import 'package:qa_genie/data/datasources/remote/generation_api.dart';

class GenerationService {
  static const bool bypassPipeline = false;

  final GenerationApi _api = GenerationApi();
  bool _isGenerating = false;
  static GenerationMetrics _lastMetrics = const GenerationMetrics();

  static GenerationMetrics get lastMetrics => _lastMetrics;

  String? _lastWarning;
  String? get lastWarning => _lastWarning;

  static const String PROMPT_VERSION = "v1.4";

  static const String _systemInstruction =
      "You are a senior QA engineer generating enterprise-grade, execution-ready manual test cases used in real QA workflows. "
      "Identify the core scenario intent first, then derive realistic preconditions, execution steps, test data, and observable expected results directly from that scenario. "
      "Use fictional or reserved testing phone numbers only. Never generate real personal contact information."
      "Generate unique, practical, non-repetitive test cases with context-aware data such as realistic emails, tokens, payloads, URLs, and credentials. "
      "Avoid generic QA wording, placeholders, vague validations, filler phrases, dummy values, and non-observable outcomes. "
      "Never use phrases like 'works correctly', 'behaves as expected', 'successful operation', 'verify success', or similar generic wording. "
      "Each step must contain a clear action, exact input data, and precise expected system behavior. "
      "Expected results must describe observable UI behavior, API responses, validations, navigation changes, state changes, persistence effects, session behavior, database effects, or security outcomes. "
      "Support validation, session, security, usability, persistence, network, navigation, permissions, and accessibility scenarios when relevant. "
      "Use only reserved documentation domains such as example.com, example.org, example.net, or .test for generated emails and URLs."
      "Restrict advanced security topics unless explicitly requested. "
      "Return ONLY a valid JSON array without markdown, comments, explanations, headings, or extra text.";

  static const List<String> _bannedPhrases = [
    // Generic filler outcomes
    "works correctly",
    "works as expected",
    "behaves as expected",
    "successful operation",
    "operation successful",
    "everything works fine",
    "expected result achieved",
    "user can proceed successfully",
    "operation completed successfully",
    "action completes without errors",

    // Generic template spam
    "scenario 1",
    "prepare for scenario",
    "execute scenario",
    "verify outcome",
    "context-specific input",

    // Placeholder / fake data
    "user@example.com",
    "test@example.com",
    "example@test.com",
    "password123",
    "admin123",
    "dummy data",
    "sample password",
    "lorem ipsum",

    // Generic meaningless actions
    "click button",
    "enter details",
    "submit form",
    "check result",
    "verify success",

    // Weak fake test data labels
    "test data",
    "correct values",
  ];

  bool _containsGarbage(TestCaseModel tc) {
    final combined =
        (tc.title +
                ' ' +
                tc.expectedResult +
                ' ' +
                tc.steps
                    .map((s) => '${s.action} ${s.data} ${s.expected}')
                    .join(' ') +
                ' ' +
                tc.preconditions.join(' '))
            .toLowerCase();
    return _bannedPhrases.any((phrase) => combined.contains(phrase));
  }

  bool _violatesPlatform(TestCaseModel tc, String platform) {
    final combined =
        '${tc.title} ${tc.expectedResult} ${tc.preconditions.join(' ')} '
        '${tc.steps.map((s) => '${s.action} ${s.data} ${s.expected}').join(' ')}';
    return PlatformRules.violatesPlatform(platform, combined);
  }

  String _intentSignature(TestCaseModel tc) {
    final normalizedTitle = tc.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();

    final firstAction = tc.steps.isNotEmpty
        ? tc.steps.first.action
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
              .trim()
        : '';

    final expected = tc.expectedResult
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();

    return '$normalizedTitle|$firstAction|$expected';
  }

  bool _passesFinalValidation(TestCaseModel tc, String platform) {
    if (_containsGarbage(tc)) return false;
    if (_violatesPlatform(tc, platform)) return false;
    if (_qualityScore(tc) < 2) return false;
    if (tc.steps.length < 3) return false;
    if (tc.expectedResult.trim().isEmpty) return false;
    return true;
  }

  int _qualityScore(TestCaseModel tc) {
    int score = 0;
    if (tc.title.trim().isNotEmpty && !tc.title.contains(RegExp(r'^\d+$')))
      score += 1;
    if (tc.steps.length >= 3) score += 1;
    if (tc.steps.any(
      (s) =>
          s.data.contains('@') &&
          !_bannedPhrases.any((p) => s.data.toLowerCase().contains(p)),
    ))
      score += 2;
    if (tc.steps.any(
      (s) =>
          s.data.length > 5 &&
          !_bannedPhrases.any((p) => s.data.toLowerCase().contains(p)),
    ))
      score += 2;
    if (tc.expectedResult.length > 40 &&
        !_bannedPhrases.any((p) => tc.expectedResult.toLowerCase().contains(p)))
      score += 2;
    if (!QaHeuristicsEngine.hasWeakExpectedResult(tc.expectedResult)) {
      score += 3;
    }
    final verbs = tc.steps
        .map((s) => s.action.split(' ').first.toLowerCase())
        .toSet();
    if (verbs.length >= 3) score += 2;

    // contextual variation bonus
    if (tc.steps.any((s) => s.action.contains(tc.feature))) score += 1;

    return score;
  }

  Future<GenerationResult> execute({
    required String module,
    required String feature,
    required String platform,
    required int maxCases,
    String? notes,
    int startIndex = 1,
    String domain = 'general',
  }) async {
    if (_isGenerating) return const GenerationResult(cases: []);
    _isGenerating = true;
    try {
      final List<TestCaseModel> generatedCases = await _performGeneration(
        module: module,
        feature: feature,
        platform: platform,
        maxCases: maxCases,
        notes: notes,
        startIndex: startIndex,
        domain: domain,
      );
      return GenerationResult(cases: generatedCases, warning: _lastWarning);
    } finally {
      _isGenerating = false;
    }
  }

  Future<List<TestCaseModel>> _performGeneration({
    required String module,
    required String feature,
    required String platform,
    required int maxCases,
    String? notes,
    required int startIndex,
    String domain = 'general',
  }) async {
    final mode = parseConstraints(notes);
    final inferredDomain = QaHeuristicsEngine.inferDomain(
      module,
      feature,
      domain,
    );
    final planner = ScenarioPlanner(
      module: module,
      feature: feature,
      platform: platform,
      mode: mode,
      count: maxCases,
      domain: inferredDomain,
    );
    final skeletons = planner.generateSkeletons();

    int aiGenerated = 0,
        aiAccepted = 0,
        filteredCount = 0,
        repairedCount = 0,
        aiCalls = 0;
    String? aiFailureReason;
    bool fallbackUsed = false;
    List<TestCaseModel> cases = [];
    final _pipelineLog = PipelineLogger(
      maxCases > 10 ? PipelineMode.pro : PipelineMode.core,
    );
    _pipelineLog.module = module;
    _pipelineLog.feature = feature;
    _pipelineLog.platform = platform;
    _pipelineLog.constraints = notes ?? '';
    _pipelineLog.requestedCount = maxCases;

    try {
      final prompt = _buildEnrichmentPrompt(
        skeletons,

        module,

        feature,

        platform,
      );

      _pipelineLog.basePrompt = prompt;

      _pipelineLog.finalApiPrompt = prompt;

      PipelineDebugStore.lastFinalPrompt = prompt;

      cases = await _api.generate(prompt);

      aiCalls++;

      if (cases.isEmpty) {
        throw Exception('AI returned zero test cases');
      }

      _pipelineLog.parsedCases = List.from(cases);

      _pipelineLog.aiGenerated = cases.length;

      aiGenerated = cases.length;
    } catch (e) {
      aiFailureReason = e.toString();

      // HARD FALLBACK RECOVERY

      cases = FallbackGenerator.generate(
        count: maxCases,
        module: module,
        feature: feature,
        platform: platform,
      );

      fallbackUsed = true;

      aiGenerated = 0;

      aiAccepted = cases.length;
    }

    final filteredGarbage = cases.where((tc) => !_containsGarbage(tc)).toList();
    if (filteredGarbage.isNotEmpty) {
      cases = filteredGarbage;
    }

    if (cases.isEmpty) {
      aiFailureReason ??= 'AI produced no usable test cases after filtering.';
    }

    for (final tc in cases) {
      if (tc.expectedResult.trim().isEmpty) {
        tc.expectedResult = _expertExpectedResult(
          tc,
          module,
          feature,
          platform,
          inferredDomain,
        );
      } else if (QaHeuristicsEngine.hasWeakExpectedResult(tc.expectedResult)) {
        tc.expectedResult = _expertExpectedResult(
          tc,
          module,
          feature,
          platform,
          inferredDomain,
        );
      }
    }

    final featureLower = feature.toLowerCase();
    final moduleLower = module.toLowerCase();
    cases = cases.where((tc) {
      final combined =
          (tc.title + ' ' + tc.steps.map((s) => s.action).join(' '))
              .toLowerCase();
      if (moduleLower.contains('login') || featureLower.contains('login')) {
        if (combined.contains('checkout') ||
            combined.contains('payment') ||
            combined.contains('card') ||
            combined.contains('order'))
          return false;
      }
      if (moduleLower.contains('payment') || featureLower.contains('payment')) {
        if (combined.contains('login') || combined.contains('signup'))
          return false;
      }
      return true;
    }).toList();

    for (final tc in cases) {
      tc.priority = _riskPriority(
        tc,
        module,
        feature,
        platform,
        inferredDomain,
      );
    }

    final beforeFilter = cases.length;
    final qualityFiltered = cases.where((tc) {
      final score = _qualityScore(tc);
      if (score >= 3) {
        _pipelineLog.recordAcceptance(tc.title, 'quality score ok ($score)');
        return true;
      }
      _pipelineLog.recordRejection(tc.title, 'quality score too low ($score)');
      return false;
    }).toList();
    cases = qualityFiltered;
    if (cases.isEmpty) {
      throw Exception('All AI cases failed quality validation');
    }
    final platformFiltered = cases
        .where((tc) => !_violatesPlatform(tc, platform))
        .toList();

    if (platformFiltered.isNotEmpty) {
      cases = platformFiltered;
    }
    filteredCount = beforeFilter - cases.length;
    aiAccepted = cases.length;
    _pipelineLog.acceptedCases = List.from(cases);
    if (bypassPipeline) {
      for (int i = 0; i < cases.length; i++) {
        cases[i].id = IdGenerator.generate(module, feature, startIndex + i);
      }
      _pipelineLog.finalCases = List.from(cases);
      _pipelineLog.rawAiResponse = PipelineDebugStore.lastRawResponse;
      _pipelineLog.cleanedAiResponse = PipelineDebugStore.lastCleanedResponse;
      _pipelineLog.finalApiPrompt = PipelineDebugStore.lastFinalPrompt;
      _pipelineLog.writeToDisk().catchError((_) {});
      return cases.take(maxCases).toList();
    }
    cases = _rebalancePriorities(cases);

    if (false) {
      print('Fallback filler disabled during AI stabilization');
    }
    final seenTitles = <String>{};
    final seenIntents = <String>{};
    final seenStepSequences = <String>{}; // To track step sequence similarity
    final seenCategories =
        <String>{}; // To track category diversity for PRO mode

    // PRO mode specific requirements
    final isProMode = maxCases > 10; // Assuming PRO mode is when maxCases > 10
    final requiredCategories = 8;
    final requiredVerbs = 12;
    final actionVerbs = <String>{};

    cases = cases.where((tc) {
      final lower = tc.title.trim().toLowerCase();
      final intent = _intentSignature(tc);
      final stepSequence = tc.steps
          .map(
            (s) => s.action
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
                .trim(),
          )
          .join('|');

      // Check for duplicate titles and intents
      if (seenTitles.contains(lower) || seenIntents.contains(intent)) {
        return false;
      }
      seenTitles.add(lower);
      seenIntents.add(intent);

      // Check for duplicate step sequences (simple check for now)
      if (seenStepSequences.contains(stepSequence)) {
        return false;
      }
      seenStepSequences.add(stepSequence);

      // Track action verbs for PRO mode
      for (final s in tc.steps) {
        if (s.action.isNotEmpty) {
          actionVerbs.add(s.action.split(' ').first.toLowerCase());
        }
      }

      if (tc.type.isNotEmpty) {
        // Simplified check as type is non-nullable
        seenCategories.add(tc.type); // Add category to track diversity
      }

      return true;
    }).toList();

    // PRO mode checks after initial filtering
    if (isProMode) {
      if (seenCategories.length < requiredCategories) {
        // Log warning if category diversity is not met
        print(
          'PRO Mode Warning: Not enough distinct categories generated. Found: ${seenCategories.length}/${requiredCategories}.',
        );
      }
      if (actionVerbs.length < requiredVerbs) {
        // Log warning if verb uniqueness is not met
        print(
          'PRO Mode Warning: Not enough unique action verbs. Found: ${actionVerbs.length}/${requiredVerbs}.',
        );
      }
      // Logic for checking repeated step sequence patterns needs more complex analysis
      // For now, rely on step sequence check above.
    }

    final beforeRepair = cases.length;
    final repair = DeterministicRepair(planner);
    cases = repair.repair(cases, maxCases);
    for (final tc in cases) {
      tc.priority = _riskPriority(
        tc,
        module,
        feature,
        platform,
        inferredDomain,
      );
    }
    cases = cases
        .where((tc) => !_containsGarbage(tc))
        .where((tc) => !_violatesPlatform(tc, platform))
        .toList();
    repairedCount = cases.length > beforeRepair
        ? cases.length - beforeRepair
        : 0;

    final seenFinal = <String>{};
    final seenFinalIntents = <String>{};

    final beforeFinalDedup = List<TestCaseModel>.from(cases);
    final finalDeduped = cases.where((tc) {
      final lower = tc.title.trim().toLowerCase();
      final intent = _intentSignature(tc);

      if (seenFinal.contains(lower) || seenFinalIntents.contains(intent)) {
        return false;
      }

      seenFinal.add(lower);
      seenFinalIntents.add(intent);

      return true;
    }).toList();

    if (finalDeduped.isNotEmpty) {
      cases = finalDeduped;
    } else {
      cases = beforeFinalDedup;
    }

    // ===== FORCE FINAL UNIQUENESS =====
    final uniqueHashes = <String>{};

    final deduped = <TestCaseModel>[];

    for (final tc in cases) {
      final hash =
          '''
      ${tc.title}
      ${tc.expectedResult}
      ${tc.steps.map((s) => '${s.action}|${s.data}|${s.expected}').join('|')}
      '''
              .toLowerCase()
              .trim();
      if (!uniqueHashes.contains(hash)) {
        uniqueHashes.add(hash);
        deduped.add(tc);
      }
    }
    if (deduped.isNotEmpty) {
      cases = deduped;
    }

    // ===== END FORCE FINAL UNIQUENESS =====

    final metrics = GenerationMetrics(
      aiGenerated: aiGenerated,
      aiAccepted: aiAccepted,
      repairedCount: repairedCount,
      filteredCount: filteredCount,
      aiCalls: aiCalls,
      aiFailure: aiFailureReason != null,
      aiFailureReason: aiFailureReason,
    );

    _lastMetrics = metrics;
    if (aiFailureReason != null) {
      _lastWarning =
          'AI generation failed during parsing, validation, or network call.';
    } else if (metrics.deterministicShare >= 0.7) {
      _lastWarning =
          'Most cases were deterministically repaired after quality filtering.';
    } else {
      _lastWarning = null;
    }
    print('[QA Genie Metrics] $metrics');

    if (false) {
      print("FINAL RECOVERY TRIGGERED: ${cases.length} -> $maxCases");

      // =====================================================
      // FINALIZATION PIPELINE
      // =====================================================

      // cases = repair.repair(cases, maxCases);

      final normalized = <TestCaseModel>[];

      for (int i = 0; i < cases.length; i++) {
        final tc = cases[i];

        final priority = i % 5 == 0 ? 'Low' : (i % 2 == 0 ? 'Medium' : 'High');

        normalized.add(
          TestCaseModel(
            id: tc.id,
            title: tc.title,
            preconditions: tc.preconditions,
            steps: tc.steps,
            expectedResult: tc.expectedResult,
            priority: priority,
            status: tc.status,
            type: tc.type,
          ),
        );
      }

      cases = normalized.take(maxCases).toList();

      print('FINAL OUTPUT: ${cases.length} cases');
    }

    _pipelineLog.aiFailure = aiFailureReason != null;

    _pipelineLog.finalCases = List.from(cases.take(maxCases).toList());
    _pipelineLog.fallbackUsed = fallbackUsed;
    _pipelineLog.aiGenerated = aiGenerated;

    _pipelineLog.rawAiResponse = PipelineDebugStore.lastRawResponse;

    _pipelineLog.cleanedAiResponse = PipelineDebugStore.lastCleanedResponse;

    _pipelineLog.finalApiPrompt = PipelineDebugStore.lastFinalPrompt;

    _pipelineLog.aiFailure = aiFailureReason != null;
    try {} catch (_) {}

    _pipelineLog.writeToDisk().catchError((_) {});
    if (cases.length < maxCases) {
      final missing = maxCases - cases.length;
      for (int i = 0; i < missing; i++) {
        final emergency = _emergencyCase(
          module,
          feature,
          platform,
          inferredDomain,
          i,
        );

        emergency.id =
            'TC_${module.toUpperCase().replaceAll(RegExp(r"[^A-Z0-9]+"), "_")}_${(cases.length + i + 1).toString().padLeft(3, '0')}';

        cases.add(emergency);
      }
    }

    cases = cases.take(maxCases).toList();
    for (int i = 0; i < cases.length; i++) {
      cases[i].id =
          'TC_${module.toUpperCase().replaceAll(RegExp(r"[^A-Z0-9]+"), "_")}_${(i + 1).toString().padLeft(3, '0')}';
    }

    return cases.take(maxCases).toList();
  }

  String _categoryToType(String cat) {
    switch (cat) {
      case 'positive':
        return 'POSITIVE';
      case 'negative':
        return 'NEGATIVE';
      case 'security':
        return 'SECURITY';
      case 'boundary':
        return 'EDGE';
      case 'validation':
        return 'VALIDATION';
      case 'session':
        return 'SESSION';
      case 'usability':
        return 'USABILITY';
      default:
        return 'GENERAL';
    }
  }

  String _smooth(String feature) {
    return feature
        .replaceAll(
          RegExp(r' with email and password', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r' using email and password', caseSensitive: false),
          '',
        )
        .trim();
  }

  TestCaseModel _emergencyCase(
    String module,
    String feature,
    String platform,
    String domain,
    int index,
  ) {
    final templates = <String, Map<String, dynamic>>{};
    final smoothFeature = _smooth(feature);

    if (platform == 'Web') {
      templates.addAll({
        'web_negative': {
          'title':
              'Verify $smoothFeature rejects invalid credentials with specific on-screen error states',
          'category': 'negative',
          'data': '{invalidEmail} / {invalidPassword}',
          'expected':
              'A clear validation message appears below the affected fields, the submission control is disabled, and the application remains in the current state.',
          'preconditions': [
            'The $smoothFeature screen is open in a fresh application session.',
          ],
        },
        'web_boundary': {
          'title':
              'Verify $smoothFeature input fields enforce character limits without layout disruptions',
          'category': 'boundary',
          'data': 'A string exceeding the 255-character threshold',
          'expected':
              'The input field prevents additional characters and displays a validation indicator without breaking the screen layout.',
          'preconditions': [
            'The $smoothFeature screen is viewed on a standard desktop resolution.',
          ],
        },
        'web_xss': {
          'title':
              'Verify $smoothFeature form handles potentially unsafe script payloads securely',
          'category': 'security',
          'data': '{xssPayload}',
          'expected':
              'The application handles the input safely by rendering it as plain text and preventing any unintended script execution.',
          'preconditions': [
            'The $smoothFeature screen is in its default state.',
          ],
        },
        'web_session': {
          'title':
              'Verify $smoothFeature session persistence across navigation events',
          'category': 'session',
          'data': '',
          'expected':
              'The application maintains the user authentication state and restores the $smoothFeature view after a screen refresh.',
          'preconditions': [
            'The user has an active session with the application.',
          ],
        },
        'web_usability': {
          'title':
              'Verify $smoothFeature accessibility via keyboard navigation',
          'category': 'usability',
          'data': '',
          'expected':
              'Interactive elements receive visible focus indicators and the $smoothFeature workflow can be completed using only the keyboard.',
          'preconditions': [
            'The screen is in its default state and no pointer device is used.',
          ],
        },
      });
    }

    if (platform == 'API') {
      final authPrecondition = domain == 'auth'
          ? 'The API endpoint is reachable and the environment is stable.'
          : 'A valid authentication token is included in the request headers.';

      templates.addAll({
        'api_positive': {
          'title':
              'Verify $smoothFeature endpoint returns a success status with the correct response format',
          'category': 'positive',
          'data': '{"email":"{validEmail}","token":"{validToken}"}',
          'expected':
              'The service returns a successful confirmation and the resource is updated.',
          'preconditions': [authPrecondition],
        },
        'api_negative': {
          'title': 'Verify $smoothFeature handling of invalid inputs',
          'category': 'negative',
          'data': '{"email":"invalid-format","unexpected_key":true}',
          'expected':
              'The service returns a clear error notification identifying the input failure, and the system remains in the original state.',
          'preconditions': [authPrecondition],
        },
        'api_security': {
          'title':
              'Verify $smoothFeature blocks requests with invalid credentials',
          'category': 'security',
          'data': '{expiredToken}',
          'expected':
              'The service denies access and ensures the security of the resource.',
          'preconditions': [
            'The request is sent with an invalid or unauthorized session identifier.',
          ],
        },
        'api_rate_limit': {
          'title': 'Verify $smoothFeature manages request frequency',
          'category': 'security',
          'data': '',
          'expected':
              'The service prevents excessive requests and provides feedback about the limitation.',
          'preconditions': [
            'The client sends requests exceeding the allowed threshold.',
          ],
        },
      });
    }

    if (platform == 'Mobile') {
      templates.addAll({
        'mobile_positive': {
          'title':
              'Verify $smoothFeature workflow completion with visual feedback',
          'category': 'positive',
          'data': '{validEmail} / {validPassword}',
          'expected':
              'The flow completes with a success indicator, visual feedback is provided, and the navigation state is updated.',
          'preconditions': ['The app is running on a standard mobile device.'],
        },
        'mobile_negative': {
          'title':
              'Verify $smoothFeature handles connectivity issues during data submission',
          'category': 'negative',
          'data': '{validEmail}',
          'expected':
              'The app detects the operation timeout, displays an actionable retry notification, and preserves the user input.',
          'preconditions': [
            'The device is configured with a limited or unstable connection.',
          ],
        },
        'mobile_session': {
          'title':
              'Verify $smoothFeature state restoration after app backgrounding',
          'category': 'session',
          'data': '',
          'expected':
              'Upon resuming from the background, the $smoothFeature screen remains accessible without an unintended application restart.',
          'preconditions': [
            'The app is moved to the background while on the $smoothFeature screen.',
          ],
        },
      });
    }

    if (templates.isEmpty) {
      templates.addAll({
        'default': {
          'title': 'Verify $smoothFeature default workflow stability',
          'category': 'positive',
          'data': '{validEmail}',
          'expected':
              'The flow completes and the user is presented with the next logical step.',
          'preconditions': ['The $smoothFeature interface is accessible.'],
        },
      });
    }

    final keys = templates.keys.toList();
    final key = keys[index % keys.length];
    final tpl = templates[key]!;

    final title = (tpl['title'] as String);
    final category = tpl['category'] as String;
    final rawData = (tpl['data'] as String);
    final data = rawData.isNotEmpty
        ? rawData
              .replaceAll(
                '{validEmail}',
                TestDataFactory.validEmail('emergency-$index'),
              )
              .replaceAll(
                '{invalidEmail}',
                TestDataFactory.invalidEmail('emergency-$index'),
              )
              .replaceAll(
                '{validPassword}',
                TestDataFactory.validPassword('emergency-$index'),
              )
              .replaceAll(
                '{invalidPassword}',
                TestDataFactory.invalidPassword('emergency-$index'),
              )
              .replaceAll('{xssPayload}', TestDataFactory.xssPayload())
              .replaceAll('{validToken}', TestDataFactory.validToken())
              .replaceAll('{expiredToken}', TestDataFactory.expiredToken())
        : '';
    final expected = (tpl['expected'] as String);
    final preconditions = (tpl['preconditions'] as List).cast<String>();

    final steps = _buildEmergencySteps(platform, smoothFeature, data, index);

    return TestCaseModel(
      title: title,
      module: module,
      feature: feature,
      platform: platform,
      preconditions: preconditions.map((e) => _cleanGeneratedText(e)).toList(),
      steps: steps,
      expectedResult: _smartExpectedResult(title, expected),
      priority: QaHeuristicsEngine.priorityFor(
        category: category,
        module: module,
        feature: feature,
        title: title,
        platform: platform,
        domain: domain,
      ),
      type: _categoryToType(category),
    );
  }

  List<TestStep> _buildEmergencySteps(
    String platform,
    String feature,
    String data,
    int seed,
  ) {
    final idx = StableHash.forText('emergency-step-$seed', 3);
    switch (platform) {
      case 'API':
        final endpoint = PlatformRules.apiEndpoint(feature);
        return [
          TestStep(
            action: 'Send request to $endpoint',
            data: data,
            expected:
                'The API returns the expected status code and response payload structure',
          ),
          TestStep(
            action: 'Validate response status and schema',
            data: '',
            expected: 'Response structure matches expected API contract',
          ),
          TestStep(
            action: 'Validate backend persistence and validation behavior',
            data: '',
            expected: 'Backend state changes are processed correctly',
          ),
        ];
      case 'Mobile':
        final openActions = [
          'Open the $feature screen from the app menu',
          'Tap the $feature icon in the navigation bar',
          'Launch the $feature view from the home screen',
        ];
        final triggerActions = [
          'Tap the primary action button',
          'Swipe to trigger the main flow',
          'Use the confirm action on the screen',
        ];
        return [
          TestStep(
            action: openActions[idx],
            data: '',
            expected: 'The $feature screen loads with all controls visible',
          ),
          TestStep(
            action: 'Enter the provided test data into the relevant fields',
            data: data,
            expected: 'Each field accepts input without crashing',
          ),
          TestStep(
            action: triggerActions[idx],
            data: '',
            expected:
                'The app responds with visual feedback and remains responsive',
          ),
        ];
      default:
        final openActions = [
          'Open the $feature screen in a supported application',
          'Navigate to the $feature URL in a fresh application tab',
          'Load the $feature screen from the application menu',
        ];
        final submitActions = [
          'Submit the $feature form',

          'Click the primary action button',

          'Complete the $feature workflow',
        ];
        return [
          TestStep(
            action: openActions[idx],
            data: '',
            expected: 'The $feature screen loads successfully',
          ),
          TestStep(
            action: 'Enter the provided test data into the relevant fields',
            data: data,
            expected:
                'The application accepts the provided input and updates the workflow state correctly',
          ),
          TestStep(
            action: submitActions[idx],
            data: '',
            expected:
                'The application updates the visible workflow state, preserves submitted data correctly, and displays the expected completion state',
          ),
        ];
    }
  }

  String _riskPriority(
    TestCaseModel tc,
    String module,
    String feature,
    String platform,
    String domain,
  ) {
    final category = QaHeuristicsEngine.inferCategory(tc.type, tc.title);
    final priority = QaHeuristicsEngine.priorityFor(
      category: category,
      module: tc.module.isNotEmpty ? tc.module : module,
      feature: tc.feature.isNotEmpty ? tc.feature : feature,
      title: tc.title,
      platform: tc.platform.isNotEmpty ? tc.platform : platform,
      domain: domain,
    );
    return PriorityUtils.normalize(priority);
  }

  String _expertExpectedResult(
    TestCaseModel tc,
    String module,
    String feature,
    String platform,
    String domain,
  ) {
    final title = tc.title.toLowerCase();
    final category = tc.type.toLowerCase();

    if (title.contains('login') || category.contains('auth')) {
      return platform == 'API'
          ? 'Authentication response returns valid token structure and unauthorized access remains blocked securely'
          : 'User session starts and unauthorized access remains restricted throughout the workflow';
    }

    if (title.contains('payment')) {
      return platform == 'API'
          ? 'Payment transaction persists without duplicate processing or inconsistent transaction state'
          : 'Payment  and transaction status is reflected accurately in the interface';
    }

    if (title.contains('scroll')) {
      return 'Application remains responsive during extended scrolling without frame drops, crashes, or rendering instability';
    }

    if (title.contains('permission') || title.contains('biometric')) {
      return 'Security validation flow behaves and invalid authentication attempts are handled safely';
    }

    if (title.contains('phone') ||
        title.contains('validation') ||
        title.contains('format')) {
      return 'Invalid input is rejected with meaningful validation feedback while maintaining stable application behavior';
    }

    return platform == 'API'
        ? 'API validation, response structure, and backend persistence behave consistently under the executed scenario'
        : 'Workflow completes and application state remains and stable after interaction';
  }

  String _buildEnrichmentPrompt(
    List<Map<String, dynamic>> skeletons,
    String module,
    String feature,
    String platform,
  ) {
    final sb = StringBuffer();
    sb.writeln(
      "DO NOT output reasoning. DO NOT use <think> tags. Return ONLY pure JSON array.",
    );
    sb.writeln('$_systemInstruction (v$PROMPT_VERSION)');
    sb.writeln('Module: $module | Feature: $feature | Platform: $platform');
    for (final sk in skeletons) {
      sb.writeln('- ${sk['title']} (${sk['category']})');
    }
    String platformRules;
    switch (platform) {
      case 'Web':
        platformRules =
            "Use ONLY application UI terminology: click, navigate, redirect, cookie, session, refresh. Never mention JWT, API, payload, headers.";
        break;
      case 'Mobile':
        platformRules =
            "Use ONLY mobile terminology: tap, swipe, rotate, biometric, permission. Never mention hover, right click, cookie, application refresh.";
        break;
      case 'API':
        platformRules =
            "Use ONLY API terminology: POST, GET, endpoint, payload, status code, header. Never mention click, navigate screen, tap screen.";
        break;
      default:
        platformRules = '';
    }
    sb.writeln(platformRules);
    sb.write(
      'JSON: [{"title":"...", "module":"$module", "feature":"$feature", "platform":"$platform", "priority":"High", "type":"Functional", "preconditions":["..."], "steps":[{"action":"","data":"","expected":""}], "expectedResult":"..."}]',
    );
    return sb.toString();
  }

  String _cleanGeneratedText(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' ,', ',')
        .replaceAll(' .', '.')
        .trim();
  }
}

String _smartExpectedResult(String title, String expected) {
  final lower = title.toLowerCase();

  final isNegative = [
    "invalid",
    "expired",
    "unauthorized",
    "malformed",
    "blocked",
    "rate limit",
    "reject",
    "denied",
  ].any(lower.contains);

  if (isNegative) {
    return "The request is rejected securely, validation rules are enforced correctly, and no unintended backend state changes occur.";
  }

  return expected;
}

List<TestCaseModel> _rebalancePriorities(List<TestCaseModel> cases) {
  for (int i = 0; i < cases.length; i++) {
    final priority = i % 5 == 0 ? 'Low' : (i % 2 == 0 ? 'Medium' : 'High');

    cases[i].priority = priority;
  }

  return cases;
}
