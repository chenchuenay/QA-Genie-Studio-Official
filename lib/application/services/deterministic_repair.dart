import 'package:qa_app/data/models/test_case_model.dart';
import 'scenario_planner.dart';
import 'platform_rules.dart';
import 'qa_heuristics_engine.dart';
import 'package:qa_app/core/utils/test_data_factory.dart';
import 'package:qa_app/core/utils/stable_hash.dart';
import 'package:qa_app/core/utils/preconditions_builder.dart';

class DeterministicRepair {
  final ScenarioPlanner planner;

  DeterministicRepair(this.planner);

  String _normalizeTitle(String title) {
    final t = title.toLowerCase();
    return t
        .replaceAll('incorrect', 'invalid')
        .replaceAll('wrong', 'invalid')
        .replaceAll('bad', 'invalid')
        .replaceAll('submit', 'send')
        .replaceAll('post', 'send')
        .replaceAll('fail', 'error')
        .replaceAll('reject', 'error')
        .replaceAll('unsuccessful', 'error')
        .replaceAll('verification', 'validation')
        .replaceAll('check', 'validation')
        .trim();
  }

  List<TestCaseModel> repair(List<TestCaseModel> cases, int targetCount) {
    if (cases.length >= targetCount) return cases;
    final existingNormalized = cases
        .map((c) => _normalizeTitle(c.title))
        .toSet();
    final skeletons = planner.generateSkeletons();
    final repaired = <TestCaseModel>[...cases];

    for (final sk in skeletons) {
      if (repaired.length >= targetCount) break;
      final title = sk['title'] as String;
      final normalized = _normalizeTitle(title);
      if (existingNormalized.contains(normalized)) continue;
      existingNormalized.add(normalized);

      final steps = _buildContextualSteps(sk);
      if (steps.length < 3) {
        steps.add(
          TestStep(
            action: 'Verify final state',
            data: '',
            expected: 'State matches expected outcome',
          ),
        );
      }

      repaired.add(
        TestCaseModel(
          title: title,
          module: sk['module'],
          feature: sk['feature'],
          platform: sk['platform'],
          priority: sk['priority'],
          type: sk['type'],
          preconditions: PreconditionsBuilder.generic(sk['feature']),
          steps: steps,
          expectedResult: _buildExpectedResult(sk),
        ),
      );
    }
    return repaired.take(targetCount).toList();
  }

  List<TestStep> _buildContextualSteps(Map<String, dynamic> sk) {
    final feature = sk['feature'] as String;
    final category = sk['category'] as String;
    final platform = sk['platform'] as String;
    final endpoint = PlatformRules.apiEndpoint(feature);
    final variants = _getVariantList(platform, category);
    final key = '$feature-$category-$platform-${sk['title']}';
    final idx = StableHash.forText(key, variants.length);
    final variant = variants[idx];
    return variant.map((step) {
      final action = step['action']!
          .replaceAll('{feature}', feature)
          .replaceAll('{endpoint}', endpoint);
      final data = step['data']!
          .replaceAll('{validEmail}', TestDataFactory.validEmail(key))
          .replaceAll('{invalidEmail}', TestDataFactory.invalidEmail(key))
          .replaceAll('{validPassword}', TestDataFactory.validPassword(key))
          .replaceAll('{invalidPassword}', TestDataFactory.invalidPassword(key))
          .replaceAll('{reference}', TestDataFactory.reference(key))
          .replaceAll('{sqlPayload}', TestDataFactory.sqlInjection())
          .replaceAll('{xssPayload}', TestDataFactory.xssPayload());
      final expected = step['expected']!
          .replaceAll('{feature}', feature)
          .replaceAll('{endpoint}', endpoint);
      return TestStep(action: action, data: data, expected: expected);
    }).toList();
  }

  // All variant lists use placeholder strings only – no runtime calls.
  List<List<Map<String, String>>> _getVariantList(
    String platform,
    String category,
  ) {
    switch (platform) {
      case 'Web':
        switch (category) {
          case 'positive':
            return [
              [
                {
                  'action': 'Navigate to {feature} page',
                  'data': '',
                  'expected': 'Page loads successfully',
                },
                {
                  'action': 'Enter valid email and password',
                  'data': '{validEmail} / {validPassword}',
                  'expected': 'Fields accept input',
                },
                {
                  'action': 'Submit the form',
                  'data': '',
                  'expected': 'System processes and shows confirmation',
                },
              ],
              [
                {
                  'action': 'Open {feature} dashboard',
                  'data': '',
                  'expected': 'Dashboard displayed',
                },
                {
                  'action': 'Fill the form with approved account values',
                  'data': '{validEmail} / {validPassword}',
                  'expected': 'Form populated',
                },
                {
                  'action': 'Press Save',
                  'data': '',
                  'expected': 'Changes saved with success notification',
                },
              ],
            ];
          case 'negative':
            return [
              [
                {
                  'action': 'Go to {feature} page',
                  'data': '',
                  'expected': 'Page accessible',
                },
                {
                  'action': 'Enter incorrect email and password',
                  'data': '{invalidEmail} / {invalidPassword}',
                  'expected': 'Field accepts input',
                },
                {
                  'action': 'Submit the form',
                  'data': '',
                  'expected': 'Error message appears near field',
                },
              ],
            ];
          case 'security':
            return [
              [
                {
                  'action': 'Open {feature} form',
                  'data': '',
                  'expected': 'Form displayed',
                },
                {
                  'action': 'Inject XSS payload in input',
                  'data': '{xssPayload}',
                  'expected': 'Script not executed',
                },
                {
                  'action': 'Submit form',
                  'data': '',
                  'expected': 'System rejects without executing payload',
                },
              ],
            ];
          default:
            return [
              [
                {
                  'action': 'Navigate to {feature} page',
                  'data': '',
                  'expected': 'Page renders the primary controls',
                },
                {
                  'action': 'Perform {feature} action',
                  'data': '{validEmail}',
                  'expected': 'The page displays a confirmation message',
                },
                {
                  'action': 'Review the confirmation state',
                  'data': '',
                  'expected': 'The page displays the saved account reference',
                },
              ],
            ];
        }
      case 'Mobile':
        switch (category) {
          case 'positive':
            return [
              [
                {
                  'action': 'Tap {feature} option',
                  'data': '',
                  'expected': 'Screen opens',
                },
                {
                  'action': 'Enter valid credentials',
                  'data': '{validEmail} / {validPassword}',
                  'expected': 'Input accepted',
                },
                {
                  'action': 'Tap Submit',
                  'data': '',
                  'expected': 'Processing completes, confirmation shown',
                },
              ],
            ];
          case 'negative':
            return [
              [
                {
                  'action': 'Tap {feature}',
                  'data': '',
                  'expected': 'Screen loads',
                },
                {
                  'action': 'Enter malformed account input and tap submit',
                  'data': '{invalidEmail} / {invalidPassword}',
                  'expected': 'Inline error appears',
                },
                {
                  'action': 'Correct the field',
                  'data': 'qa_user_locked@domain.test',
                  'expected':
                      'Error remains until every required field passes validation',
                },
              ],
            ];
          default:
            return [
              [
                {
                  'action': 'Tap {feature}',
                  'data': '',
                  'expected': 'Screen opens',
                },
                {
                  'action': 'Perform action',
                  'data': '{validEmail}',
                  'expected': 'The app displays a confirmation message',
                },
                {
                  'action': 'Review the updated screen state',
                  'data': '',
                  'expected': 'The latest account reference is visible',
                },
              ],
            ];
        }
      case 'API':
        switch (category) {
          case 'positive':
            return [
              [
                {
                  'action': 'POST {endpoint}',
                  'data':
                      '{"email":"{validEmail}","password":"{validPassword}"}',
                  'expected': 'HTTP 200 with documented response envelope',
                },
                {
                  'action': 'Verify response schema',
                  'data': '',
                  'expected': 'All required fields present',
                },
                {
                  'action': 'GET {endpoint}',
                  'data': '',
                  'expected': 'Data matches created resource',
                },
              ],
            ];
          case 'negative':
            return [
              [
                {
                  'action': 'POST {endpoint}',
                  'data': '{"email":""}',
                  'expected': 'HTTP 400 with error description',
                },
                {
                  'action': 'Inspect error payload',
                  'data': '',
                  'expected': 'Message indicates missing field',
                },
                {
                  'action': 'Repeat GET {endpoint} for the same resource',
                  'data': '',
                  'expected':
                      'Resource state remains unchanged after rejected request',
                },
              ],
            ];
          default:
            return [
              [
                {
                  'action': 'POST {endpoint}',
                  'data': '{"key":"value"}',
                  'expected': 'HTTP 200 with documented response envelope',
                },
                {
                  'action': 'Inspect response fields',
                  'data': '',
                  'expected':
                      'Response includes resource identifier and timestamp',
                },
                {
                  'action': 'GET {endpoint}',
                  'data': '',
                  'expected': 'Returned resource matches the submitted payload',
                },
              ],
            ];
        }
      default:
        return [
          [
            {
              'action': 'Perform {feature} action',
              'data': '{validEmail}',
              'expected': 'The feature records the submitted account reference',
            },
            {
              'action': 'Review resulting state',
              'data': '',
              'expected': 'The latest state is visible to the tester',
            },
          ],
        ];
    }
  }

  String _buildExpectedResult(Map<String, dynamic> sk) {
    final category = sk['category'] as String;
    final feature = sk['feature'] as String;
    final module = sk['module'] as String;
    final platform = sk['platform'] as String;
    final title = sk['title'] as String;
    return QaHeuristicsEngine.expectedResult(
      platform: platform,
      category: category,
      module: module,
      feature: feature,
      title: title,
      domain: planner.domain,
    );
  }
}
