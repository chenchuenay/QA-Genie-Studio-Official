import 'package:qa_genie/data/models/test_case_model.dart';
import 'scenario_planner.dart';
import 'platform_rules.dart';
import 'qa_heuristics_engine.dart';
import 'package:qa_genie/core/utils/test_data_factory.dart';
import 'package:qa_genie/core/utils/stable_hash.dart';
import 'package:qa_genie/engine/builders/preconditions_builder.dart';

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
    final smoothFeature = _smooth(feature);
    final category = sk['category'] as String;
    final platform = sk['platform'] as String;
    final endpoint = PlatformRules.apiEndpoint(feature);
    final variants = _getVariantList(platform, category);
    final key = '$feature-$category-$platform-${sk['title']}';
    final idx = StableHash.forText(key, variants.length);
    final variant = variants.isNotEmpty ? variants[idx] : [];

    final res = <TestStep>[];
    for (int i = 0; i < variant.length; i++) {
      final step = variant[i];
      final action = step['action']!
          .replaceAll('{feature}', smoothFeature)
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
          .replaceAll('{feature}', smoothFeature)
          .replaceAll('{endpoint}', endpoint);

      res.add(TestStep(action: action, data: data, expected: expected));

      // Deterministic variation: inject a verification step for specific seeds
      if (i == 1 &&
          StableHash.forText(key, 10) > 7 &&
          category == 'positive' &&
          platform != 'API') {
        res.add(
          TestStep(
            action:
                'Verify the interface remains responsive and displays no immediate errors',
            data: '',
            expected:
                'The UI is stable and the primary action remains available.',
          ),
        );
      }
    }

    if (res.length < 3 && platform != 'API') {
      res.add(
        TestStep(
          action: 'Observe the final state of the {feature} module'.replaceAll(
            '{feature}',
            smoothFeature,
          ),
          data: '',
          expected:
              'The system state matches the expected outcome for this scenario.',
        ),
      );
    }

    return res;
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
                  'action': 'Navigate to the {feature} URL in a browser',
                  'data': '',
                  'expected':
                      'The page displays all expected interactive elements and the user interface remains stable.',
                },
                {
                  'action':
                      'Enter valid credentials into the {feature} form inputs',
                  'data': '{validEmail} / {validPassword}',
                  'expected':
                      'The inputs accept the data and provide clear indicators of valid entry.',
                },
                {
                  'action': 'Complete the {feature} submission',
                  'data': '',
                  'expected':
                      'The application processes the submission and redirects to the expected success or dashboard view.',
                },
              ],
            ];
          case 'negative':
            return [
              [
                {
                  'action':
                      'Open the {feature} page and simulate a slow network connection',
                  'data': '',
                  'expected':
                      'The interface displays a status indicator informing the user of the connectivity issues.',
                },
                {
                  'action':
                      'Attempt to submit the {feature} form with incorrect data',
                  'data': '{invalidEmail} / {invalidPassword}',
                  'expected':
                      'The interface prevents submission and highlights the fields that require correction.',
                },
                {
                  'action': 'Verify the specific error message text',
                  'data': '',
                  'expected':
                      'An actionable error message is displayed to the user.',
                },
              ],
            ];
          case 'security':
            return [
              [
                {
                  'action':
                      'Navigate to the {feature} entry point and verify session security',
                  'data': '',
                  'expected':
                      'The session is secure, sensitive information is not exposed, and no system debug details are visible.',
                },
                {
                  'action':
                      'Attempt to submit a malicious text payload into the {feature} input',
                  'data': '{xssPayload}',
                  'expected':
                      'The application handles the input securely and does not execute the payload.',
                },
                {
                  'action':
                      'Attempt to bypass authentication by navigating to a restricted page',
                  'data': '',
                  'expected':
                      'The system prevents access and redirects to the login page.',
                },
              ],
            ];
          default:
            return [
              [
                {
                  'action':
                      'Navigate to the primary {feature} interface and check for responsiveness',
                  'data': '',
                  'expected':
                      'The page layout adapts to the browser window size without horizontal scrolling.',
                },
                {
                  'action':
                      'Complete the {feature} workflow using only keyboard Tab and Enter keys',
                  'data': '{validEmail}',
                  'expected':
                      'The focus order is logical and the user can reach the final "Success" state without a mouse.',
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
                  'action':
                      'Launch the mobile application and select the {feature} option',
                  'data': '',
                  'expected':
                      'The screen transitions to the {feature} interface and displays its primary controls.',
                },
                {
                  'action':
                      'Provide the necessary {feature} details through the input fields',
                  'data': '{validEmail} / {validPassword}',
                  'expected':
                      'The input fields capture the data and the primary action control becomes interactable.',
                },
                {
                  'action': 'Perform a list refresh action',
                  'data': '',
                  'expected':
                      'The screen updates to reflect the most current state from the system.',
                },
              ],
            ];
          case 'negative':
            return [
              [
                {
                  'action':
                      'Move the application to the background while on the {feature} screen',
                  'data': '',
                  'expected':
                      'The application preserves the current workflow state without interruption.',
                },
                {
                  'action':
                      'Attempt to proceed with an incorrect authentication entry',
                  'data': '{invalidPassword}',
                  'expected':
                      'An error notification appears and the input highlights the failure.',
                },
              ],
            ];
          case 'security':
            return [
              [
                {
                  'action':
                      'Verify privacy settings while on the {feature} screen',
                  'data': '',
                  'expected':
                      'Sensitive data is masked from view during screen interactions.',
                },
                {
                  'action':
                      'Trigger the {feature} flow while declining required device permissions',
                  'data': '',
                  'expected':
                      'The app explains why the permission is required and handles the denial without failure.',
                },
              ],
            ];
          default:
            return [
              [
                {
                  'action':
                      'Open the {feature} view and rotate the device to Landscape mode',
                  'data': '',
                  'expected':
                      'The UI adapts to the new orientation and all controls remain accessible within the viewport.',
                },
                {
                  'action':
                      'Execute the primary {feature} action on a high-latency (EDGE) connection',
                  'data': '{validEmail}',
                  'expected':
                      'A loading spinner is shown and the app prevents multiple taps on the submit button.',
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
                  'action':
                      'Send a request to the {endpoint} with valid authentication details',
                  'data': '{validEmail} / {validPassword}',
                  'expected':
                      'The service confirms successful authentication and returns the expected result structure.',
                },
                {
                  'action':
                      'Verify the returned data against expected outcomes',
                  'data': '',
                  'expected': 'All required fields are present and accurate.',
                },
              ],
            ];
          case 'negative':
            return [
              [
                {
                  'action':
                      'Send a request to the {endpoint} with invalid data',
                  'data': 'Invalid payload',
                  'expected':
                      'The service returns a clear notification identifying the input error.',
                },
                {
                  'action':
                      'Send a request with a payload that exceeds system limitations',
                  'data': 'Over-sized payload',
                  'expected':
                      'The service rejects the submission and notifies of the limitation.',
                },
              ],
            ];
          case 'security':
            return [
              [
                {
                  'action':
                      'Attempt access to {endpoint} without proper credentials',
                  'data': '',
                  'expected':
                      'The service denies the request and ensures security policies are maintained.',
                },
                {
                  'action': 'Attempt to send an expired authentication request',
                  'data': 'Expired credentials',
                  'expected':
                      'The service rejects the request and prompts for valid authentication.',
                },
              ],
            ];
        }
      default:
        return [
          [
            {
              'action': 'Perform the primary {feature} operation',
              'data': '{validEmail}',
              'expected':
                  'The system processes the operation and updates the visible state.',
            },
          ],
        ];
    }
    return [];
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
