// ============================================================

// FILE: lib/engine/builders/preconditions_builder.dart

// ============================================================

class PreconditionsBuilder {
  const PreconditionsBuilder();

  static List<String> login() => [
    'User account is registered and active.',

    'Chrome browser is launched.',

    'User is on the Login page.',
  ];

  static List<String> passwordReset() => [
    'User account exists in the system.',

    'Registered email inbox is accessible.',
  ];

  static List<String> paymentFlow() => [
    'User is authenticated successfully.',

    'Payment gateway services are operational.',

    'Test payment method is available.',
  ];

  static List<String> api() => [
    'API server is deployed and reachable.',

    'Authentication token is available.',

    'Required API permissions are granted.',
  ];

  static List<String> mobile() => [
    'Application is installed successfully.',

    'Device network connectivity is stable.',

    'Required device permissions are enabled.',
  ];

  static List<String> generic(String feature) => [
    'Application is deployed and running.',

    'User has appropriate permissions to access $feature.',
  ];

  static List<String> security() => [
    'Security monitoring services are active.',

    'Authentication system is operational.',

    'Sensitive endpoints are protected.',
  ];

  static List<String> validation() => [
    'Input form is accessible.',

    'Validation rules are configured in the backend.',
  ];

  static List<String> resilience() => [
    'Application services are running normally.',

    'Recovery and retry services are enabled.',
  ];
}
