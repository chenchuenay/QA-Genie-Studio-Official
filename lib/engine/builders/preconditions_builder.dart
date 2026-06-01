class PreconditionsBuilder {
  static List<String> generic(String feature) {
    return ['User is logged into the application', 'Network connectivity is stable'];
  }

  List<String> build({
    required String feature,
    required String platform,
    required String category,
  }) {
    final pre = <String>[];
    if (platform == 'API') {
      pre.add('API service is reachable');
      pre.add('Authentication token is available');
    } else {
      pre.add('User is logged into the application');
      pre.add('Network connectivity is stable');
    }
    if (category == 'session') pre.add('An active session exists');
    if (category == 'security') pre.add('Application has security headers enabled');
    pre.add('$feature workflow is accessible');
    return pre;
  }
}