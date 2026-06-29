import 'dart:math';

class StepPhase {
  final String id;
  final String label;

  const StepPhase(this.id, this.label);

  static const navigate = StepPhase('navigate', 'Navigate');
  static const input = StepPhase('input', 'Input');
  static const execute = StepPhase('execute', 'Execute');
  static const verify = StepPhase('verify', 'Verify');
}

class VariationPool {
  static const Map<String, List<String>> navigate = {
    'web': [
      'Navigate to the {entity} page',
      'Open the {entity} section',
      'Go to {entity}',
      'Access the {entity} module',
      'Locate {entity} in the navigation menu',
    ],
    'mobile': [
      'Open the {entity} screen',
      'Tap to access {entity}',
      'Navigate to {entity}',
    ],
    'api': [
      'Prepare {entity} request payload',
      'Set up {entity} API request',
    ],
  };

  static const Map<String, List<String>> input = {
    'text': [
      'Enter {value} in the {label} field',
      'Type {value} as {label}',
      'Fill in {label} with {value}',
      'Provide {label}: {value}',
      'Input {value} for {label}',
    ],
    'select': [
      'Select {value} from the {label} dropdown',
      'Choose {value} as {label}',
      'Pick {value} for {label}',
    ],
    'identifier': [
      'Enter {label}: {value}',
      'Provide {label}: {value}',
      'Input the {label}: {value}',
    ],
    'sensitive': [
      'Enter {label}: (hidden input)',
      'Provide your {label}',
      'Fill in {label} securely',
    ],
    'api': [
      'Set {key}: {value}',
      'Include {key} = {value} in payload',
      'Add {key}: {value} to the request body',
    ],
  };

  static const Map<String, List<String>> execute = {
    'web': [
      'Click "{button}"',
      'Press the "{button}" button',
      'Click on "{button}"',
    ],
    'mobile': [
      'Tap "{button}"',
      'Tap the "{button}" button',
    ],
    'api': [
      'Send {method} request to /{endpoint}',
      'Execute {method} /{endpoint}',
    ],
  };

  static const Map<String, List<String>> verify = {
    'success': [
      'Verify {outcome} is displayed',
      'Confirm {outcome} appears',
      'Check that {outcome} is shown',
      'Ensure {outcome} is visible',
    ],
    'error': [
      'Verify error: {message}',
      'Confirm error message: {message}',
      'Check validation shows: {message}',
    ],
    'state': [
      'Verify the {entity} state changes to {state}',
      'Confirm {entity} is now {state}',
      'Check {entity} status: {state}',
    ],
    'api': [
      'Assert HTTP {status} response',
      'Verify response status code is {status}',
      'Check response: HTTP {status}',
    ],
  };

  static String pick(
    String pool,
    String variant,
    Map<String, String> substitutions,
    Random rng,
  ) {
    List<String>? templates;
    switch (pool) {
      case 'navigate':
        templates = navigate[variant];
      case 'input':
        templates = input[variant];
      case 'execute':
        templates = execute[variant];
      case 'verify':
        templates = verify[variant];
    }
    if (templates == null || templates.isEmpty) return '';
    final t = templates[rng.nextInt(templates.length)];
    var result = t;
    for (final entry in substitutions.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }
}
