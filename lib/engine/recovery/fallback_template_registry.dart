// lib/engine/recovery/fallback_template_registry.dart

class FallbackTemplateRegistry {
  const FallbackTemplateRegistry();

  List<String> categories() {
    return const [
      'Positive',
      'Negative',
      'Boundary',
      'Security',
      'Session',
      'Validation',
    ];
  }

  List<String> priorities() {
    return const ['Low', 'Medium', 'High', 'Critical'];
  }

  List<String> supportedTypes() {
    return const [
      'Functional',
      'Validation',
      'Security',
      'Session',
      'Boundary',
    ];
  }
}
