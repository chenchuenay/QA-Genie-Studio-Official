import 'package:qa_app/data/models/test_case_model.dart';

class FallbackGenerator {
  static const Map<String, List<Map<String, String>>> _scenarioMap = {
    'login': [
      {'title': 'Verify login with valid credentials', 'type': 'POSITIVE'},
      {'title': 'Verify login failure with incorrect password', 'type': 'NEGATIVE'},
      {'title': 'Verify login failure with empty password field', 'type': 'NEGATIVE'},
      {'title': 'Verify login field security against SQL injection', 'type': 'SECURITY'},
      {'title': 'Verify login with multiple failed attempts', 'type': 'NEGATIVE'},
    ],
    'signup': [
      {'title': 'Verify signup with valid details', 'type': 'POSITIVE'},
      {'title': 'Verify signup with already registered email', 'type': 'NEGATIVE'},
      {'title': 'Verify signup with missing required fields', 'type': 'NEGATIVE'},
    ],
    'password': [
      {'title': 'Verify password reset with valid email', 'type': 'POSITIVE'},
      {'title': 'Verify password reset with non‑existent email', 'type': 'NEGATIVE'},
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
      'login', 'signup', 'password', 'payment', 'search', 'upload',
      'email', 'otp', 'cart', 'checkout', 'profile', 'settings',
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

    for (final key in keywords) {
      final scenarios = _scenarioMap[key] ?? [];
      for (final sc in scenarios) {
        final title = sc['title']!;
        if (seenTitles.contains(title.toLowerCase())) continue;
        seenTitles.add(title.toLowerCase());
        cases.add(TestCaseModel(
          title: title,
          module: module,
          feature: feature,
          platform: platform,
          preconditions: ['Standard environment', 'User not logged in'],
          steps: [
            TestStep(action: 'Navigate to relevant page', expected: 'Page loaded'),
            TestStep(action: 'Perform action', data: '', expected: 'Appropriate response'),
          ],
          expectedResult: 'System behaves correctly',
          priority: 'Medium',
          type: sc['type'] ?? 'GENERAL',
        ));
      }
      if (cases.length >= count) break;
    }

    int i = cases.length + 1;
    while (cases.length < count) {
      cases.add(TestCaseModel(
        title: 'Verify $feature - scenario $i',
        module: module,
        feature: feature,
        platform: platform,
        preconditions: ['Standard environment'],
        steps: [TestStep(action: 'Perform action $i', expected: 'Expected outcome')],
        expectedResult: 'System behaves as expected',
        priority: 'Medium',
        type: 'GENERAL',
      ));
      i++;
    }
    return cases.take(count).toList();
  }
}
