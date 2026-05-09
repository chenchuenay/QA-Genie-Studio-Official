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

  String _smooth(String feature) {
    return feature
        .replaceAll(RegExp(r' with email and password', caseSensitive: false), '')
        .replaceAll(RegExp(r' using email and password', caseSensitive: false), '')
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
    final variant = variants[idx];
    
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
      if (i == 1 && StableHash.forText(key, 10) > 7 && category == 'positive' && platform != 'API') {
        res.add(TestStep(
          action: 'Verify the interface remains responsive and displays no immediate errors',
          data: '',
          expected: 'The UI is stable and the primary action remains available.',
        ));
      }
    }
    
    if (res.length < 3 && platform != 'API') {
      res.add(TestStep(
        action: 'Observe the final state of the {feature} module'.replaceAll('{feature}', smoothFeature),
        data: '',
        expected: 'The system state matches the expected outcome for this scenario.',
      ));
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
                  'action': 'Navigate to the {feature} URL in a fresh browser session',
                  'data': '',
                  'expected': 'The page renders with all interactive elements visible and the interface is stable.',
                },
                {
                  'action': 'Input valid credentials into the {feature} form fields',
                  'data': '{validEmail} / {validPassword}',
                  'expected': 'The input fields reflect the entered text and provide immediate feedback.',
                },
                {
                  'action': 'Submit the form and observe the application response',
                  'data': '',
                  'expected': 'A success notification is displayed and the application routes to the dashboard.',
                },
              ],
              [
                {
                  'action': 'Access the {feature} dashboard from the application menu',
                  'data': '',
                  'expected': 'The dashboard module loads within 2 seconds with populated data.',
                },
                {
                  'action': 'Update the {feature} configuration with new parameters',
                  'data': 'Reference: {reference}',
                  'expected': 'The submission control becomes active and no validation errors are shown.',
                },
                {
                  'action': 'Execute the save action and refresh the page',
                  'data': '',
                  'expected': 'The system persists the changes across the page reload.',
                },
              ],
            ];
          case 'negative':
            return [
              [
                {
                  'action': 'Open the {feature} page and simulate a network disruption',
                  'data': '',
                  'expected': 'The page remains responsive and displays a connectivity indicator.',
                },
                {
                  'action': 'Attempt to submit the {feature} form with invalid data',
                  'data': '{invalidEmail} / {invalidPassword}',
                  'expected': 'The application prevents the submission and highlights the affected fields.',
                },
                {
                  'action': 'Restore connectivity and retry the submission',
                  'data': '',
                  'expected': 'The system provides a clear error message describing the validation failure.',
                },
              ],
            ];
          case 'security':
            return [
              [
                {
                  'action': 'Navigate to the {feature} entry point',
                  'data': '',
                  'expected': 'The page is loaded over a secure connection.',
                },
                {
                  'action': 'Attempt to submit a potentially unsafe script payload into the {feature} input',
                  'data': '{xssPayload}',
                  'expected': 'The application handles the input securely and renders it as plain text.',
                },
                {
                  'action': 'Verify the application state for any unintended execution',
                  'data': '',
                  'expected': 'No unexpected actions are triggered and the interface remains secure.',
                },
              ],
            ];
          default:
            return [
              [
                {
                  'action': 'Navigate to the primary {feature} interface',
                  'data': '',
                  'expected': 'The page renders all primary controls according to established design patterns.',
                },
                {
                  'action': 'Execute the {feature} workflow using standard keyboard navigation',
                  'data': '{validEmail}',
                  'expected': 'Focus indicators are visible and the workflow completes as intended.',
                },
                {
                  'action': 'Inspect the resulting state in the application interface',
                  'data': '',
                  'expected': 'The latest state is correctly recorded with reference {reference}.',
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
                  'action': 'Launch the app and select the {feature} module',
                  'data': '',
                  'expected': 'The screen transitions smoothly with a standard visual animation.',
                },
                {
                  'action': 'Fill in the {feature} requirements using the on-screen keyboard',
                  'data': '{validEmail} / {validPassword}',
                  'expected': 'The app remains responsive and input is captured accurately.',
                },
                {
                  'action': 'Perform a refresh gesture on the {feature} screen',
                  'data': '',
                  'expected': 'The screen updates with the latest system state for {feature}.',
                },
              ],
            ];
          case 'negative':
            return [
              [
                {
                  'action': 'Navigate to the {feature} screen and move the app to the background',
                  'data': '',
                  'expected': 'The app state is preserved while in the background.',
                },
                {
                  'action': 'Resume the app and enter malformed input for {feature}',
                  'data': '{invalidEmail} / {invalidPassword}',
                  'expected': 'An inline validation error appears with visual or tactile feedback.',
                },
                {
                  'action': 'Attempt to proceed to the next step',
                  'data': '',
                  'expected': 'The progression is blocked and the error field is highlighted.',
                },
              ],
            ];
          default:
            return [
              [
                {
                  'action': 'Open the {feature} view from the main navigation',
                  'data': '',
                  'expected': 'The screen loads and displays all required interactive components.',
                },
                {
                  'action': 'Perform the primary {feature} action on a limited connection',
                  'data': '{validEmail}',
                  'expected': 'The app displays a loading indicator and remains stable.',
                },
                {
                  'action': 'Review the updated screen once the operation completes',
                  'data': '',
                  'expected': 'The latest transaction reference {reference} is clearly visible.',
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
                  'action': 'Send a POST request to {endpoint} with a valid payload',
                  'data': '{"email":"{validEmail}","password":"{validPassword}"}',
                  'expected': 'A success status code is returned with the correct response format.',
                },
                {
                  'action': 'Validate the response metadata for security standards',
                  'data': '',
                  'expected': 'Security headers and metadata are present in the response.',
                },
                {
                  'action': 'Execute a retrieval request for the {feature} resource',
                  'data': '',
                  'expected': 'The response matches the originally submitted data.',
                },
              ],
            ];
          case 'negative':
            return [
              [
                {
                  'action': 'Send a POST request to {endpoint} with an empty body',
                  'data': '{}',
                  'expected': 'A client error status is returned with a descriptive error message.',
                },
                {
                  'action': 'Submit a request with a field exceeding the accepted threshold',
                  'data': '{"large_field":"' + 'A' * 5000 + '"}',
                  'expected': 'The server rejects the request with an appropriate error status.',
                },
                {
                  'action': 'Verify that no new records were created in the system',
                  'data': '',
                  'expected': 'The resource state remains unchanged after the failed attempts.',
                },
              ],
            ];
          default:
            return [
              [
                {
                  'action': 'Execute a resource check request to {endpoint}',
                  'data': '',
                  'expected': 'A success status is returned with appropriate metadata.',
                },
                {
                  'action': 'Send a POST request with a unique transaction identifier {reference}',
                  'data': '{"action":"{feature}"}',
                  'expected': 'The request is processed successfully.',
                },
                {
                  'action': 'Retry the same request with the same transaction identifier',
                  'data': '',
                  'expected': 'The server handles the duplicate request without side effects.',
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
              'expected': 'The system records the submitted account reference {reference}.',
            },
            {
              'action': 'Validate the resulting state in the system of record',
              'data': '',
              'expected': 'The persistence layer reflects the updated state for {feature}.',
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
