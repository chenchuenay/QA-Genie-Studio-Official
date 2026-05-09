import 'package:qa_app/core/utils/priority_utils.dart';
import 'package:qa_app/core/utils/id_generator.dart';
import 'package:qa_app/data/datasources/remote/generation_api.dart';
import 'package:qa_app/data/models/test_case_model.dart';
import 'package:qa_app/application/services/scenario_planner.dart';
import 'package:qa_app/application/services/deterministic_repair.dart';
import 'package:qa_app/application/services/generation_mode.dart';
import 'package:qa_app/application/services/generation_metrics.dart';
import 'package:qa_app/application/services/platform_rules.dart';
import 'package:qa_app/application/services/qa_heuristics_engine.dart';
import 'package:qa_app/core/utils/test_data_factory.dart';
import 'package:qa_app/core/utils/stable_hash.dart';

class GenerationService {
  final GenerationApi _api = GenerationApi();
  bool _isGenerating = false;
  static GenerationMetrics _lastMetrics = const GenerationMetrics();
  static String? _lastWarning;

  static GenerationMetrics get lastMetrics => _lastMetrics;
  static String? get lastWarning => _lastWarning;

  static const String PROMPT_VERSION = "v1.4";

  static const String _systemInstruction =
      "You are a senior QA engineer responsible for creating professional, execution-ready manual test cases used in real QA workflows. "
      "Your primary goal is to generate test cases that mimic those written by experienced QA engineers, focusing on realism, uniqueness, and practicality."
      "For each feature, first identify the core scenario intent (e.g., 'successful login', 'invalid password entry', 'session expiration')."
      "THEN, derive all other aspects – preconditions, specific steps, test data, and expected results – directly from that identified scenario intent."
      "NEVER reuse generic step bundles or expected result phrases like:"
      "'observe final state',"
      "'system state matches expected outcome',"
      "'verify operation success',"
      "'execute primary action',"
      "'check responsiveness',"
      "'works correctly',"
      "'behaves as expected',"
      "'successful operation',"
      "'operation successful',"
      "or similar generic wording. Use explicit and observable outcomes."
      "Ensure test data is diverse, context-aware, and realistic (e.g., unique emails, realistic passwords, valid/expired tokens, specific URLs, relevant API payloads). NEVER use placeholders or dummy values like 'user@example.com' or 'password123'."
      "Avoid repetition of credentials, tokens, names, or values across test cases."
      "Each execution step MUST contain:"
      " a clear user or system action,"
      " the exact input or test data used,"
      " and the precise expected behaviour or response from the system."
      "Expected results MUST describe observable application behaviour, API responses, validations, state changes, database effects, navigation changes, or security outcomes."
      "Add dedicated scenario categories with specific grammar:"
      "- Validation: Focus on data formats, required fields, and business rules."
      "- Session: Cover login/logout, expiry, persistence, and state restoration."
      "- Security: Address authentication, authorization, and basic vulnerabilities. RESTRICT advanced security topics (e.g., certificate pinning, API key exposure, MITM, clipboard attacks) unless explicitly requested by the user."
      "- Usability: Test ease of use, clarity, and interactive elements."
      "- State Persistence: Verify data integrity and state across sessions or reloads."
      "- Network Behavior: Test responses to connectivity changes, latency, and timeouts."
      "- Navigation: Ensure clear and logical transitions between screens/endpoints."
      "- Permissions: Validate handling of user and device permissions."
      "- Accessibility: Check for keyboard navigation, screen reader compatibility, and clear focus indicators."
      "Generate outputs that resemble test cases written by experienced QA engineers working in enterprise-grade software teams. "
      "Return ONLY a valid JSON array. "
      "Do not return markdown, comments, explanations, headings, or additional text.";

  static const List<String> _bannedPhrases = [
    "everything works fine",
    "works correctly",
    "works as expected",
    "behaves as expected",
    "successful operation",
    "operation successful",
    "scenario 1",
    "prepare for scenario",
    "execute scenario",
    "verify outcome",
    "test data",
    "valid data",
    "invalid data",
    "correct values",
    "dummy data",
    "user@example.com",
    "test@example.com",
    "example@test.com",
    "password123",
    "admin123",
    "sample password",
    "click button",
    "enter details",
    "submit form",
    "check result",
    "verify success",
    "context-specific input",
    "action completes without errors",
    "system is in default state",
    "functional requirements",
    "system responds correctly",
    "expected result achieved",
    "user can proceed successfully",
    "operation completed successfully",
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
    final title = tc.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    final firstAction = tc.steps.isNotEmpty
        ? tc.steps.first.action.toLowerCase().replaceAll(
            RegExp(r'[^a-z0-9]+'),
            ' ',
          )
        : '';
    final expected = tc.expectedResult.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      ' ',
    );
    final tokens = '$title $firstAction $expected'
        .split(' ')
        .map((t) => t.trim())
        .where((t) => t.length > 3)
        .toList();
    tokens.sort();
    return tokens.take(18).join(' ');
  }

  bool _passesFinalValidation(TestCaseModel tc, String platform) {
    if (_containsGarbage(tc)) return false;
    if (_violatesPlatform(tc, platform)) return false;
    if (_qualityScore(tc) < 5) return false;
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

  Future<List<TestCaseModel>> execute({
    required String module,
    required String feature,
    required String platform,
    required int maxCases,
    String? notes,
    int startIndex = 1,
    String domain = 'general',
  }) async {
    if (_isGenerating) return [];
    _isGenerating = true;
    try {
      return await _performGeneration(
        module: module,
        feature: feature,
        platform: platform,
        maxCases: maxCases,
        notes: notes,
        startIndex: startIndex,
        domain: domain,
      );
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
    List<TestCaseModel> cases = [];

    try {
      final prompt = _buildEnrichmentPrompt(
        skeletons,
        module,
        feature,
        platform,
      );
      cases = await _api.generate(prompt);
      aiCalls++;
      aiGenerated = cases.length;
    } catch (e) {
      aiFailureReason = e.toString();
    }

    cases = cases.where((tc) => !_containsGarbage(tc)).toList();

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
    cases = cases.where((tc) => _qualityScore(tc) >= 3).toList();
    cases = cases.where((tc) => !_violatesPlatform(tc, platform)).toList();
    filteredCount = beforeFilter - cases.length;
    aiAccepted = cases.length;

    final seenTitles = <String>{};
    final seenIntents = <String>{};
    final seenStepSequences = <List<String>>{}; // To track step sequence similarity
    final seenCategories = <String>{}; // To track category diversity for PRO mode

    // PRO mode specific requirements
    final isProMode = maxCases > 10; // Assuming PRO mode is when maxCases > 10
    final requiredCategories = 8;
    final requiredVerbs = 12;
    final actionVerbs = <String>{};

    cases = cases.where((tc) {
      final lower = tc.title.trim().toLowerCase();
      final intent = _intentSignature(tc);
      final stepSequence = tc.steps.map((s) => s.action.toLowerCase()).toList();

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

      if (tc.type.isNotEmpty) { // Simplified check as type is non-nullable
        seenCategories.add(tc.type); // Add category to track diversity
      }

      return true;
    }).toList();

    // PRO mode checks after initial filtering
    if (isProMode) {
      if (seenCategories.length < requiredCategories) {
        // This check is more for reporting; filtering based on it is complex here
        // print('PRO Mode Warning: Not enough distinct categories generated. Found: ${seenCategories.length}');
      }
      if (actionVerbs.length < requiredVerbs) {
        // Similar to categories, for reporting and potential future filtering
        // print('PRO Mode Warning: Not enough unique action verbs. Found: ${actionVerbs.length}');
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
    repairedCount = cases.length - beforeRepair;

    final seenFinal = <String>{};
    final seenFinalIntents = <String>{};
    cases = cases.where((tc) {
      final lower = tc.title.trim().toLowerCase();
      final intent = _intentSignature(tc);
      if (seenFinal.contains(lower) || seenFinalIntents.contains(intent)) {
        return false;
      }
      seenFinal.add(lower);
      seenFinalIntents.add(intent);
      return true;
    }).toList();
    cases = cases.take(maxCases).toList();

    final feat = feature.isNotEmpty ? feature : module;
    int fillNum = cases.length + 1;
    cases = cases.where((tc) => _passesFinalValidation(tc, platform)).toList();
    fillNum = cases.length + 1;
    int guard = 0;
    while (cases.length < maxCases && guard < maxCases * 5) {
      final emergency = _emergencyCase(
        module,
        feat,
        platform,
        inferredDomain,
        fillNum,
      );
      if (_passesFinalValidation(emergency, platform)) {
        cases.add(emergency);
      }
      fillNum++;
      guard++;
    }
    cases = cases.take(maxCases).toList();

    for (int i = 0; i < cases.length; i++) {
      cases[i].id = IdGenerator.generate(module, feature, startIndex + i);
    }

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
          'AI enrichment failed; deterministic recovery completed the suite.';
    } else if (metrics.deterministicShare >= 0.7) {
      _lastWarning =
          'Most cases were deterministically repaired after quality filtering.';
    } else {
      _lastWarning = null;
    }
    print('[QA Genie Metrics] $metrics');
    print('FINAL OUTPUT: ${cases.length} cases (requested $maxCases)');
    return cases;
  }

  String _categoryToType(String cat) {
    switch (cat) {
      case 'positive': return 'POSITIVE';
      case 'negative': return 'NEGATIVE';
      case 'security': return 'SECURITY';
      case 'boundary': return 'EDGE';
      case 'validation': return 'VALIDATION';
      case 'session': return 'SESSION';
      case 'usability': return 'USABILITY';
      default: return 'GENERAL';
    }
  }

  String _smooth(String feature) {
    return feature
        .replaceAll(RegExp(r' with email and password', caseSensitive: false), '')
        .replaceAll(RegExp(r' using email and password', caseSensitive: false), '')
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
          'title': 'Verify $smoothFeature rejects invalid credentials with specific on-screen error states',
          'category': 'negative',
          'data': '{invalidEmail} / {invalidPassword}',
          'expected': 'A clear validation message appears below the affected fields, the submission control is disabled, and the application remains in the current state.',
          'preconditions': ['The $smoothFeature page is open in a fresh browser session.'],
        },
        'web_boundary': {
          'title': 'Verify $smoothFeature input fields enforce character limits without layout disruptions',
          'category': 'boundary',
          'data': 'A string exceeding the 255-character threshold',
          'expected': 'The input field prevents additional characters and displays a validation indicator without breaking the page layout.',
          'preconditions': ['The $smoothFeature page is viewed on a standard desktop resolution.'],
        },
        'web_xss': {
          'title': 'Verify $smoothFeature form handles potentially unsafe script payloads securely',
          'category': 'security',
          'data': '{xssPayload}',
          'expected': 'The application handles the input safely by rendering it as plain text and preventing any unintended script execution.',
          'preconditions': ['The $smoothFeature page is in its default state.'],
        },
        'web_session': {
          'title': 'Verify $smoothFeature session persistence across navigation events',
          'category': 'session',
          'data': '',
          'expected': 'The application maintains the user authentication state and restores the $smoothFeature view correctly after a page refresh.',
          'preconditions': ['The user has an active session with the application.'],
        },
        'web_usability': {
          'title': 'Verify $smoothFeature accessibility via keyboard navigation',
          'category': 'usability',
          'data': '',
          'expected': 'Interactive elements receive visible focus indicators and the $smoothFeature workflow can be completed using only the keyboard.',
          'preconditions': ['The page is in its default state and no pointer device is used.'],
        },
      });
    }

    if (platform == 'API') {
      final authPrecondition = domain == 'auth'
          ? 'The API endpoint is reachable and the environment is stable.'
          : 'A valid authentication token is included in the request headers.';
      
      templates.addAll({
        'api_positive': {
          'title': 'Verify $smoothFeature endpoint returns a success status with the correct response format',
          'category': 'positive',
          'data': '{"email":"{validEmail}","token":"{validToken}"}',
          'expected': 'The service returns a successful confirmation and the resource is correctly updated.',
          'preconditions': [authPrecondition],
        },
        'api_negative': {
          'title': 'Verify $smoothFeature handling of invalid inputs',
          'category': 'negative',
          'data': '{"email":"invalid-format","unexpected_key":true}',
          'expected': 'The service returns a clear error notification identifying the input failure, and the system remains in the original state.',
          'preconditions': [authPrecondition],
        },
        'api_security': {
          'title': 'Verify $smoothFeature blocks requests with invalid credentials',
          'category': 'security',
          'data': '{expiredToken}',
          'expected': 'The service denies access and ensures the security of the resource.',
          'preconditions': ['The request is sent with an invalid or unauthorized session identifier.'],
        },
        'api_rate_limit': {
          'title': 'Verify $smoothFeature manages request frequency',
          'category': 'security',
          'data': '',
          'expected': 'The service prevents excessive requests and provides feedback about the limitation.',
          'preconditions': ['The client sends requests exceeding the allowed threshold.'],
        },
      });
    }

    if (platform == 'Mobile') {
      templates.addAll({
        'mobile_positive': {
          'title': 'Verify $smoothFeature workflow completion with appropriate visual feedback',
          'category': 'positive',
          'data': '{validEmail} / {validPassword}',
          'expected': 'The flow completes with a success indicator, appropriate visual feedback is provided, and the navigation state is updated.',
          'preconditions': ['The app is running on a standard mobile device.'],
        },
        'mobile_negative': {
          'title': 'Verify $smoothFeature handles connectivity issues during data submission',
          'category': 'negative',
          'data': '{validEmail}',
          'expected': 'The app detects the operation timeout, displays an actionable retry notification, and preserves the user input.',
          'preconditions': ['The device is configured with a limited or unstable connection.'],
        },
        'mobile_session': {
          'title': 'Verify $smoothFeature state restoration after app backgrounding',
          'category': 'session',
          'data': '',
          'expected': 'Upon resuming from the background, the $smoothFeature screen remains accessible without an unintended application restart.',
          'preconditions': ['The app is moved to the background while on the $smoothFeature screen.'],
        },
      });
    }

    if (templates.isEmpty) {
      templates.addAll({
        'default': {
          'title': 'Verify $smoothFeature default workflow stability',
          'category': 'positive',
          'data': '{validEmail}',
          'expected': 'The flow completes and the user is presented with the next logical step.',
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
            .replaceAll('{validEmail}', TestDataFactory.validEmail('emergency-$index'))
            .replaceAll('{invalidEmail}', TestDataFactory.invalidEmail('emergency-$index'))
            .replaceAll('{validPassword}', TestDataFactory.validPassword('emergency-$index'))
            .replaceAll('{invalidPassword}', TestDataFactory.invalidPassword('emergency-$index'))
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
      preconditions: preconditions,
      steps: steps,
      expectedResult: expected,
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
          TestStep(action: 'Send request to $endpoint', data: data, expected: 'Response is received'),
          TestStep(action: 'Verify operation success', data: '', expected: 'The result matches the expected resource update.'),
          TestStep(action: 'Examine response contents', data: '', expected: 'Response contains the appropriate confirmation.'),
        ];
      case 'Mobile':
        final openActions = ['Open the $feature screen from the app menu', 'Tap the $feature icon in the navigation bar', 'Launch the $feature view from the home screen'];
        final triggerActions = ['Tap the primary action button', 'Swipe to trigger the main flow', 'Use the confirm action on the screen'];
        return [
          TestStep(action: openActions[idx], data: '', expected: 'The $feature screen loads with all controls visible'),
          TestStep(action: 'Enter the provided test data into the relevant fields', data: data, expected: 'Each field accepts input without crashing'),
          TestStep(action: triggerActions[idx], data: '', expected: 'The app responds with visual feedback and remains responsive'),
        ];
      default:
        final openActions = ['Open the $feature page in a supported browser', 'Navigate to the $feature URL in a fresh browser tab', 'Load the $feature page from the application menu'];
        final submitActions = ['Submit the $feature form', 'Click the primary action button', 'Press Enter to trigger the main flow'];
        return [
          TestStep(action: openActions[idx], data: '', expected: 'The page renders all required controls'),
          TestStep(action: 'Enter the provided test data into the form fields', data: data, expected: 'Fields accept input and show no JavaScript errors'),
          TestStep(action: submitActions[idx], data: '', expected: 'The system responds within 3 seconds with appropriate feedback'),
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
    final category = QaHeuristicsEngine.inferCategory(tc.type, tc.title);
    return QaHeuristicsEngine.expectedResult(
      platform: tc.platform.isNotEmpty ? tc.platform : platform,
      category: category,
      module: tc.module.isNotEmpty ? tc.module : module,
      feature: tc.feature.isNotEmpty ? tc.feature : feature,
      title: tc.title,
      domain: domain,
    );
  }

  String _buildEnrichmentPrompt(
    List<Map<String, dynamic>> skeletons,
    String module,
    String feature,
    String platform,
  ) {
    final sb = StringBuffer();
    sb.writeln('$_systemInstruction (v$PROMPT_VERSION)');
    sb.writeln('Module: $module | Feature: $feature | Platform: $platform');
    for (final sk in skeletons) {
      sb.writeln('- ${sk['title']} (${sk['category']})');
    }
    String platformRules;
    switch (platform) {
      case 'Web':
        platformRules =
            "Use ONLY browser UI terminology: click, navigate, redirect, cookie, session, refresh. Never mention JWT, API, payload, headers.";
        break;
      case 'Mobile':
        platformRules =
            "Use ONLY mobile terminology: tap, swipe, rotate, biometric, permission. Never mention hover, right click, cookie, browser refresh.";
        break;
      case 'API':
        platformRules =
            "Use ONLY API terminology: POST, GET, endpoint, payload, status code, header. Never mention click, navigate page, tap screen.";
        break;
      default:
        platformRules = '';
    }
    sb.writeln(platformRules);
    sb.write(
      'JSON: [{"title":"...", "module":"$module", "feature":"$feature", "platform":"$platform", "priority":"High", "type":"Functional", "preconditions":[], "steps":[{"step":1,"action":"","data":"","expected":""}]}]',
    );
    return sb.toString();
  }
}
