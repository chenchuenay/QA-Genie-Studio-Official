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
                  'action': 'Navigate to the {feature} URL in a supported web browser (Chrome/Firefox/Safari)',
                  'data': '',
                  'expected': 'The page renders completely, all interactive elements are clickable, and no console errors are present.',
                },
                {
                  'action': 'Enter valid credentials into the {feature} form inputs',
                  'data': '{validEmail} / {validPassword}',
                  'expected': 'The inputs accept the data and any associated inline validation indicators show a success state.',
                },
                {
                  'action': 'Click the primary submission button and observe the browser redirect',
                  'data': '',
                  'expected': 'The application processes the request, displays a success toast message, and redirects to the dashboard URL.',
                },
              ],
              [
                {
                  'action': 'Open the {feature} dashboard via the application sidebar navigation',
                  'data': '',
                  'expected': 'The dashboard component mounts correctly and displays the current state for {feature}.',
                },
                {
                  'action': 'Update the {feature} configuration fields with new valid parameters',
                  'data': 'Reference: {reference}',
                  'expected': 'The "Save Changes" button becomes enabled and the interface remains responsive.',
                },
                {
                  'action': 'Execute a "Save" action followed by a manual browser refresh (F5)',
                  'data': '',
                  'expected': 'The system persists the changes across the session and the updated data is visible after the refresh.',
                },
              ],
            ];
          case 'negative':
            return [
              [
                {
                  'action': 'Open the {feature} page and simulate a slow 3G network connection via DevTools',
                  'data': '',
                  'expected': 'The page displays a loading skeleton or progress indicator while resources are being fetched.',
                },
                {
                  'action': 'Attempt to submit the {feature} form with malformed data',
                  'data': '{invalidEmail} / {invalidPassword}',
                  'expected': 'The UI prevents submission and applies a red focus ring to the invalid input fields.',
                },
                {
                  'action': 'Verify the specific error message text displayed in the UI',
                  'data': '',
                  'expected': 'The message "Invalid format" or equivalent is visible and actionable for the user.',
                },
              ],
            ];
          case 'security':
            return [
              [
                {
                  'action': 'Navigate to the {feature} entry point and inspect the "Set-Cookie" headers',
                  'data': '',
                  'expected': 'Session cookies are marked as HttpOnly and Secure to prevent unauthorized access.',
                },
                {
                  'action': 'Inject a malicious script payload into the {feature} text input',
                  'data': '{xssPayload}',
                  'expected': 'The application sanitizes the input, rendering the script as a literal string without execution.',
                },
                {
                  'action': 'Attempt to bypass client-side validation using the browser console',
                  'data': 'document.querySelector("form").submit()',
                  'expected': 'The server-side validation rejects the request and returns a secure error response.',
                },
              ],
            ];
          default:
            return [
              [
                {
                  'action': 'Navigate to the primary {feature} interface and check for responsiveness',
                  'data': '',
                  'expected': 'The page layout adjusts correctly to the browser window size without horizontal scrolling.',
                },
                {
                  'action': 'Complete the {feature} workflow using only keyboard Tab and Enter keys',
                  'data': '{validEmail}',
                  'expected': 'The focus order is logical and the user can reach the final "Success" state without a mouse.',
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
                  'action': 'Launch the mobile application and tap the {feature} icon on the tab bar',
                  'data': '',
                  'expected': 'The app performs a smooth transition and the {feature} screen becomes active.',
                },
                {
                  'action': 'Fill the {feature} fields using the system on-screen keyboard',
                  'data': '{validEmail} / {validPassword}',
                  'expected': 'The app remains lag-free and the "Submit" button becomes active after the last field is filled.',
                },
                {
                  'action': 'Perform a "Pull-to-Refresh" gesture on the {feature} list',
                  'data': '',
                  'expected': 'A haptic pulse is felt and the screen data is refreshed from the local cache/remote server.',
                },
              ],
            ];
          case 'negative':
            return [
              [
                {
                  'action': 'While on the {feature} screen, move the application to the background',
                  'data': '',
                  'expected': 'The application state is suspended correctly without any crashes.',
                },
                {
                  'action': 'Resume the application and enter an incorrect password for {feature}',
                  'data': '{invalidPassword}',
                  'expected': 'An inline error tooltip appears and the device provides a haptic feedback notification.',
                },
                {
                  'action': 'Attempt to proceed while the device is in Airplane Mode',
                  'data': '',
                  'expected': 'The app displays a "No Internet Connection" alert and prevents the data submission.',
                },
              ],
            ];
          case 'security':
            return [
              [
                {
                  'action': 'Attempt to capture a screenshot of the {feature} sensitive data screen',
                  'data': '',
                  'expected': 'The app prevents the screenshot or masks sensitive fields (e.g., password/SSN) in the capture.',
                },
                {
                  'action': 'Trigger the {feature} flow and decline the requested device permissions',
                  'data': '',
                  'expected': 'The app handles the permission denial gracefully, explaining why the permission is needed.',
                },
              ],
            ];
          default:
            return [
              [
                {
                  'action': 'Open the {feature} view and rotate the device to Landscape mode',
                  'data': '',
                  'expected': 'The UI adapts to the new orientation and all controls remain accessible within the viewport.',
                },
                {
                  'action': 'Execute the primary {feature} action on a high-latency (EDGE) connection',
                  'data': '{validEmail}',
                  'expected': 'A loading spinner is shown and the app prevents multiple taps on the submit button.',
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
                  'action': 'Send a POST request to {endpoint} with a valid JSON payload',
                  'data': '{"email":"{validEmail}","password":"{validPassword}"}',
                  'expected': 'The server returns a 201 Created or 200 OK status with an application/json Content-Type.',
                },
                {
                  'action': 'Verify the response body schema against the documentation',
                  'data': '',
                  'expected': 'All mandatory fields (id, status, timestamp) are present and match the expected data types.',
                },
                {
                  'action': 'Send a GET request to {endpoint}/{{id}} using the ID from the previous step',
                  'data': '',
                  'expected': 'The resource is retrieved successfully and matches the originally submitted data.',
                },
              ],
            ];
          case 'negative':
            return [
              [
                {
                  'action': 'Send a POST request to {endpoint} with a malformed JSON string',
                  'data': '{"email": "{validEmail}", "broken": }',
                  'expected': 'The server returns a 400 Bad Request status with a "Malformed JSON" error message.',
                },
                {
                  'action': 'Submit a request to {endpoint} with a field exceeding the database limit',
                  'data': '{"description":"' + 'A' * 4000 + '"}',
                  'expected': 'The server rejects the request with a 413 Payload Too Large or 400 Bad Request status.',
                },
                {
                  'action': 'Verify that no side effects or new records were created for {feature}',
                  'data': '',
                  'expected': 'A subsequent LIST request confirms the resource count remains unchanged.',
                },
              ],
            ];
          case 'security':
            return [
              [
                {
                  'action': 'Send a POST request to {endpoint} without an Authorization header',
                  'data': '',
                  'expected': 'The server returns a 401 Unauthorized status with a WWW-Authenticate header.',
                },
                {
                  'action': 'Attempt a SQL injection attack via the {feature} query parameters',
                  'data': '{endpoint}?id={sqlPayload}',
                  'expected': 'The server returns a 400 Bad Request or 200 OK with no results, ensuring no data leak.',
                },
                {
                  'action': 'Send a request using an expired JWT token for {feature}',
                  'data': 'Authorization: Bearer {expiredToken}',
                  'expected': 'The server returns a 401 Unauthorized with the message "Token expired".',
                },
              ],
            ];
          default:
            return [
              [
                {
                  'action': 'Perform a HEAD request to {endpoint} to check resource availability',
                  'data': '',
                  'expected': 'The server returns a 200 OK status with the correct headers but an empty body.',
                },
                {
                  'action': 'Execute a request to {endpoint} with an Idempotency-Key: {reference}',
                  'data': '',
                  'expected': 'The request is processed and the server returns a success status.',
                },
                {
                  'action': 'Retry the identical request with the same Idempotency-Key',
                  'data': '',
                  'expected': 'The server returns the cached response from the first request with no new side effects.',
                },
              ],
            ];
        }
      default:
        return [
          [
            {
              'action': 'Perform the primary {feature} operation using default parameters',
              'data': '{validEmail}',
              'expected': 'The system completes the operation and provides a unique reference code {reference}.',
            },
            {
              'action': 'Verify the updated state for {feature} in the audit logs',
              'data': '',
              'expected': 'A new entry is recorded with the correct timestamp and user identifier.',
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
