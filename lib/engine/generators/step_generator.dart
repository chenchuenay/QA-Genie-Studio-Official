import '../models/scenario.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';

class StepGenerator {
  static List<Map<String, String>> generate(
    Scenario scenario,
    String platform,
    Map<String, String> testData,
  ) {
    final isApi = platform.toUpperCase() == 'API';
    final isMobile = platform.toUpperCase() == 'MOBILE';
    final steps = <Map<String, String>>[];

    // Entry
    final entity = scenario.entity.displayName;
    steps.add(
      isApi
          ? {
              'action': 'Prepare $entity request',
              'data': '',
              'expected': 'Request ready',
            }
          : (isMobile
                ? {
                    'action': 'Open $entity screen',
                    'data': '',
                    'expected': '$entity screen displayed',
                  }
                : {
                    'action': 'Navigate to $entity page',
                    'data': '',
                    'expected': '$entity page loaded',
                  }),
    );

    // Input steps
    for (final entry in testData.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key == 'valid_flag' || key == 'invalid_flag') continue;
      if (value.isEmpty) continue;
      steps.add(
        isApi
            ? {
                'action': 'Set $key=$value',
                'data': value,
                'expected': 'Payload includes $key',
              }
            : (isMobile
                  ? {
                      'action': 'Enter $key: $value',
                      'data': value,
                      'expected': '$key field shows entered value',
                    }
                  : {
                      'action': 'Enter $key: $value',
                      'data': value,
                      'expected': '$key field shows entered value',
                    }),
      );
    }

    // Execution
    final actionName = scenario.action.displayName;
    steps.add(
      isApi
          ? {
              'action': 'Execute $actionName call',
              'data': '',
              'expected': scenario.isPositive ? 'HTTP 2xx' : 'HTTP 4xx',
            }
          : (isMobile
                ? {
                    'action': 'Tap $actionName',
                    'data': '',
                    'expected': scenario.isPositive
                        ? 'Action processed'
                        : 'Error shown',
                  }
                : {
                    'action': 'Click $actionName',
                    'data': '',
                    'expected': scenario.isPositive
                        ? 'Action processed'
                        : 'Validation error',
                  }),
    );

    // Verification
    final outcome = scenario.isPositive ? 'success' : 'error';
    steps.add(
      isApi
          ? {
              'action': 'Verify response state',
              'data': '',
              'expected': 'Response indicates $outcome',
            }
          : {
              'action': 'Check result',
              'data': '',
              'expected': scenario.isPositive
                  ? 'Success message displayed'
                  : 'Error message displayed',
            },
    );

    return steps;
  }
}
