
class PreconditionsBuilder {
  static List<String> login() => [
    'User account is registered and active.',
    'Chrome browser is launched.',
    'User is on the Login page.',
  ];

  static List<String> passwordReset() => [
    'User account exists in the system.',
    'Registered email inbox is accessible.',
  ];

  static List<String> generic(String feature) => [
    'Application is deployed and running.',
    'User has appropriate permissions to access $feature.',
  ];
}
