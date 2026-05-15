import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/data/models/test_case_model.dart';

class FallbackGenerator {
  static const Map<String, List<Map<String, String>>> _scenarioMap = {
    'login': [
      {'title': 'Verify login with valid credentials', 'type': 'POSITIVE'},
      {
        'title': 'Verify login failure with incorrect password',
        'type': 'NEGATIVE',
      },
      {
        'title': 'Verify login failure with empty password field',
        'type': 'NEGATIVE',
      },
      {
        'title': 'Verify login field security against SQL injection',
        'type': 'SECURITY',
      },
      {
        'title': 'Verify login with multiple failed attempts',
        'type': 'NEGATIVE',
      },
    ],
    'signup': [
      {'title': 'Verify signup with valid details', 'type': 'POSITIVE'},
      {
        'title': 'Verify signup with already registered email',
        'type': 'NEGATIVE',
      },
      {
        'title': 'Verify signup with missing required fields',
        'type': 'NEGATIVE',
      },
    ],
    'password': [
      {'title': 'Verify password reset with valid email', 'type': 'POSITIVE'},
      {
        'title': 'Verify password reset with non-existent email',
        'type': 'NEGATIVE',
      },
    ],
    'payment': [
      {'title': 'Verify payment with valid card', 'type': 'POSITIVE'},
      {'title': 'Verify payment with expired card', 'type': 'NEGATIVE'},
      {'title': 'Verify payment with insufficient balance', 'type': 'NEGATIVE'},
    ],
    'search': [
      {'title': 'Verify search with matching keywords', 'type': 'POSITIVE'},
      {'title': 'Verify search with no results', 'type': 'EDGE'},
    ],
    'upload': [
      {'title': 'Verify file upload with valid file', 'type': 'POSITIVE'},
      {'title': 'Verify upload size limit', 'type': 'EDGE'},
    ],
  };

  static List<String> _extractKeywords(String text) {
    final important = [
      'login',
      'signup',
      'password',
      'payment',
      'search',
      'upload',
      'email',
      'otp',
      'cart',
      'checkout',
      'profile',
      'settings',
    ];
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    return words.where((w) => important.contains(w)).toList();
  }

  static List<TestCaseModel> generate({
    required int count,
    required String module,
    required String feature,
    required String platform,
  }) {
    final cases = <TestCaseModel>[];
    final keywords = _extractKeywords('$module $feature');
    final seenTitles = <String>{};
    final seenIntents = <String>{};
    final resolvedFeature = feature.isNotEmpty ? feature : module;

    for (final key in keywords) {
      final scenarios = _scenarioMap[key] ?? [];
      for (final sc in scenarios) {
        final title = sc['title']!;

        if (seenTitles.contains(title.toLowerCase())) continue;

        final generatedSteps = _buildSteps(
          title: title,
          type: sc['type'] ?? 'GENERAL',
          feature: resolvedFeature,
          platform: platform,
        );

        final intentHash = generatedSteps
            .map((s) => s.action.toLowerCase().trim())
            .join('|');

        if (seenIntents.contains(intentHash)) continue;

        seenIntents.add(intentHash);
        seenTitles.add(title.toLowerCase());

        cases.add(
          TestCaseModel(
            source: CaseSource.fallback,
            title: title
                .replaceAll('{feature}', resolvedFeature)
                .replaceAll('{module}', module),
            module: module,
            feature: feature,
            platform: platform,
            preconditions: [
              'A clean QA account exists for $resolvedFeature execution.',
              'The $platform test environment is reachable and seeded with known user records.',
            ],
            steps: generatedSteps,
            expectedResult: _expectedResult(
              title: title,
              type: sc['type'] ?? 'GENERAL',
              feature: resolvedFeature,
              platform: platform,
            ),
            priority: 'Medium',
            type: sc['type'] ?? 'GENERAL',
          ),
        );
      }
      if (cases.length >= count) break;
    }

    int i = cases.length + 1;
    int safety = 0;

    while (cases.length < count && safety < count * 3) {
      safety++;
      cases.add(
        TestCaseModel(
          source: CaseSource.fallback,
          title: 'Verify $resolvedFeature stability - variant $i',
          module: module,
          feature: feature,
          platform: platform,
          preconditions: ['Standard QA environment'],
          steps: _buildSteps(
            title: 'Verify $resolvedFeature stability - variant $i',
            type: 'GENERAL',
            feature: resolvedFeature,
            platform: platform,
          ),
          expectedResult:
              'The $resolvedFeature workflow stays responsive, preserves entered data, and displays a visible completion or validation state.',
          priority: 'Medium',
          type: 'GENERAL',
        ),
      );
      i++;
    }
    return cases.take(count).toList();
  }

  static List<TestStep> _buildSteps({
    required String title,
    required String type,
    required String feature,
    required String platform,
  }) {
    final lower = title.toLowerCase();
    final isSecurity = type == 'SECURITY' || lower.contains('injection');
    final isNegative = type == 'NEGATIVE' || lower.contains('failure');
    final data = isSecurity
        ? "' OR '1'='1"
        : isNegative
        ? 'qa.locked@example.net / Invalid-Pass-9041'
        : 'qa.primary@example.net / Secure-Pass-4821';

    if (platform == 'API') {
      return [
        TestStep(
          action:
              'Send a POST request to the ${feature.toLowerCase().replaceAll(' ', '-')} endpoint',
          data: data,
          expected:
              'The service returns a documented status code and response body.',
        ),
        TestStep(
          action: isSecurity
              ? 'Inspect the response for rejected authentication state'
              : 'Validate the response schema and required fields',
          data: '',
          expected: isSecurity
              ? 'The response denies access and omits stack traces or sensitive fields.'
              : 'The payload contains the required contract fields with stable value types.',
        ),
        TestStep(
          action: 'Query the persisted record state for the submitted account',
          data: 'qa.primary@example.net',
          expected:
              'The backend record reflects only the state changes allowed by the scenario.',
        ),
      ];
    }

    return [
      TestStep(
        action: 'Navigate to the primary $feature interface',
        data: '',
        expected:
            'The page displays the required fields, labels, and primary action control.',
      ),
      TestStep(
        action: isSecurity
            ? 'Enter the SQL injection payload into the credential field'
            : 'Enter the prepared credentials into the $feature fields',
        data: data,
        expected: isSecurity
            ? 'The input remains text in the field and no script, query, or debug output appears.'
            : 'Each field accepts the entered value and shows its validation state.',
      ),
      TestStep(
        action: isNegative || isSecurity
            ? 'Submit the form and inspect the validation message'
            : 'Submit the form and observe the destination view',
        data: '',
        expected: isNegative || isSecurity
            ? 'A specific error message appears near the affected field and the user remains unauthenticated.'
            : 'The application redirects to the authenticated landing view and shows the active session state.',
      ),
    ];
  }

  static String _expectedResult({
    required String title,
    required String type,
    required String feature,
    required String platform,
  }) {
    final lower = title.toLowerCase().trim();
    if (type == 'SECURITY' || lower.contains('injection')) {
      return 'The request is blocked, no authenticated session is created, and sensitive implementation details remain hidden from the response.';
    }
    if (type == 'NEGATIVE' || lower.contains('failure')) {
      return 'The application rejects the submitted data, keeps the user on the $feature screen, and displays a field-level error message.';
    }
    if (platform == 'API') {
      return 'The service returns the documented response contract and persists only the intended state transition.';
    }
    return 'The application opens the authenticated destination view, displays the active session indicator, and records the expected audit state.';
  }
}
